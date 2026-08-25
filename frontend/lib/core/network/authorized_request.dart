import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../errors/app_exception.dart';
import '../storage/session_storage.dart';

/// Runs [call] with the current access token; on a 401 it forces one
/// refresh attempt (via AuthRepository.restoreSession, which already owns
/// the refresh-token flow) and retries once. Shared by every repository
/// that calls an authenticated endpoint (Player, Club, SavedPlayers).
Future<T> runAuthorized<T>(
  Ref ref,
  SessionStorage storage,
  Future<T> Function(String accessToken) call,
) async {
  final token = await storage.accessToken;
  if (token == null) throw const AppException('You are not signed in.');
  try {
    return await call(token);
  } on AppException catch (e) {
    if (e.statusCode != 401) rethrow;
    await ref.read(authRepositoryProvider).restoreSession();
    final refreshed = await storage.accessToken;
    if (refreshed == null) rethrow;
    return call(refreshed);
  }
}
