import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/locale/locale_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/entities/user_role.dart';
import 'session_state.dart';

/// Owns "who is logged in right now." Screens read this to decide what to
/// show; it does not own screen-local form state (see login/register pages)
/// or one-off calls like forgot/reset-password that don't change who is
/// authenticated.
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() => const SessionState.initial();

  /// The one error message this app writes itself. Every other
  /// [SessionState.errorMessage] is the backend's own wording, shown as-is
  /// (see [AppException]); this covers the failures that never reach the
  /// backend at all. Resolved through [localeProvider] rather than a
  /// BuildContext, which a Notifier does not have — and it has to be
  /// resolved rather than hardcoded, in an app whose default language is
  /// Arabic.
  String _genericError() =>
      lookupAppLocalizations(ref.read(localeProvider)).genericErrorMessage;

  Future<void> restore() async {
    try {
      final user = await ref.read(authRepositoryProvider).restoreSession();
      state = SessionState(
        status: user != null
            ? SessionStatus.authenticated
            : SessionStatus.unauthenticated,
        user: user,
      );
    } catch (_) {
      state = const SessionState(status: SessionStatus.unauthenticated);
    }
  }

  Future<bool> login({required String identifier, required String password}) async {
    state = state.copyWith(status: SessionStatus.authenticating, clearError: true);
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .login(identifier: identifier, password: password);
      state = SessionState(status: SessionStatus.authenticated, user: user);
      return true;
    } on AppException catch (e) {
      state = SessionState(
        status: SessionStatus.unauthenticated,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      // Anything that isn't an AppException — a missing platform plugin, a
      // decoding failure — still has to land the state machine on a
      // terminal state. Without this the status stays `authenticating`
      // forever and the screen shows a spinner that never resolves and
      // never explains itself.
      state = SessionState(
        status: SessionStatus.unauthenticated,
        errorMessage: _genericError(),
      );
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    state = state.copyWith(status: SessionStatus.authenticating, clearError: true);
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .register(email: email, password: password, role: role);
      state = SessionState(status: SessionStatus.authenticated, user: user);
      return true;
    } on AppException catch (e) {
      state = SessionState(
        status: SessionStatus.unauthenticated,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      // Same terminal-state guarantee as login() above.
      state = SessionState(
        status: SessionStatus.unauthenticated,
        errorMessage: _genericError(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const SessionState(status: SessionStatus.unauthenticated);
  }

  Future<bool> updateAccount({
    String? email,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .updateAccount(
            email: email,
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
      state = state.copyWith(user: user, clearError: true);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }
}

final sessionControllerProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);
