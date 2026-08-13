import '../entities/app_user.dart';
import '../entities/user_role.dart';

/// All methods throw [AppException] (core/errors) on failure — repository
/// implementations translate backend error responses into it.
abstract class AuthRepository {
  Future<AppUser> register({
    required String email,
    required String password,
    required UserRole role,
  });

  /// [identifier] is either an email or a phone number (club-created
  /// players log in with their phone as username) — the backend resolves
  /// whichever it is.
  Future<AppUser> login({required String identifier, required String password});

  Future<void> logout();

  /// Called once at app start. Returns the current user if a stored
  /// session is still valid (refreshing the access token if needed), or
  /// `null` if there is no session / it could not be restored.
  Future<AppUser?> restoreSession();

  Future<void> forgotPassword(String email);

  Future<void> resetPassword({required String token, required String newPassword});

  Future<AppUser> updateAccount({
    String? email,
    String? currentPassword,
    String? newPassword,
  });
}
