import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../core/storage/session_storage_provider.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/app_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._storage);

  final AuthRemoteDataSource _remote;
  final SessionStorage _storage;

  @override
  Future<AppUser> register({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final json = await _remote.register(
      email: email,
      password: password,
      role: role.wireValue,
    );
    return _persistAndReturnUser(json);
  }

  @override
  Future<AppUser> login({required String identifier, required String password}) async {
    final json = await _remote.login(identifier: identifier, password: password);
    return _persistAndReturnUser(json);
  }

  @override
  Future<void> logout() async {
    final refreshToken = _storage.refreshToken;
    if (refreshToken != null) {
      try {
        await _remote.logout(refreshToken);
      } catch (_) {
        // Local session is cleared regardless — an unreachable/failing
        // backend must never trap the user in a logged-in UI state.
      }
    }
    await _storage.clear();
  }

  @override
  Future<AppUser?> restoreSession() async {
    final accessToken = _storage.accessToken;
    if (accessToken == null) return null;

    try {
      final json = await _remote.getCurrentUser(accessToken);
      return AppUserModel.fromJson(json);
    } on AppException {
      final refreshed = await _tryRefresh();
      if (!refreshed) {
        await _storage.clear();
        return null;
      }
      try {
        final json = await _remote.getCurrentUser(_storage.accessToken!);
        return AppUserModel.fromJson(json);
      } on AppException {
        await _storage.clear();
        return null;
      }
    }
  }

  @override
  Future<void> forgotPassword(String email) => _remote.forgotPassword(email);

  @override
  Future<void> resetPassword({required String token, required String newPassword}) =>
      _remote.resetPassword(token: token, newPassword: newPassword);

  @override
  Future<AppUser> updateAccount({
    String? email,
    String? currentPassword,
    String? newPassword,
  }) async {
    Future<AppUser> attempt() async {
      final json = await _remote.updateCurrentUser(
        _storage.accessToken!,
        email: email,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return AppUserModel.fromJson(json);
    }

    try {
      return await attempt();
    } on AppException {
      if (!await _tryRefresh()) rethrow;
      return attempt();
    }
  }

  Future<AppUser> _persistAndReturnUser(Map<String, dynamic> json) async {
    await _storage.saveTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
    return AppUserModel.fromJson(json['user'] as Map<String, dynamic>);
  }

  /// Attempts one refresh using the stored refresh token. Returns whether
  /// it succeeded; on success the new tokens are already persisted.
  Future<bool> _tryRefresh() async {
    final refreshToken = _storage.refreshToken;
    if (refreshToken == null) return false;
    try {
      final json = await _remote.refresh(refreshToken);
      await _storage.saveTokens(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );
      return true;
    } on AppException {
      return false;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(sessionStorageProvider),
  ),
);
