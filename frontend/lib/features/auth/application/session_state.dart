import '../domain/entities/app_user.dart';

enum SessionStatus {
  /// Still restoring from storage — splash screen waits on this.
  unknown,
  authenticating,
  authenticated,
  unauthenticated,
}

class SessionState {
  const SessionState({required this.status, this.user, this.errorMessage});

  const SessionState.initial() : this(status: SessionStatus.unknown);

  final SessionStatus status;
  final AppUser? user;
  final String? errorMessage;

  SessionState copyWith({
    SessionStatus? status,
    AppUser? user,
    String? errorMessage,
    bool clearError = false,
  }) => SessionState(
    status: status ?? this.status,
    user: user ?? this.user,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}
