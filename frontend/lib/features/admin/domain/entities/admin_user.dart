import '../../../auth/domain/entities/user_role.dart';

class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    required this.isModerator,
    this.suspendedUntil,
    this.suspensionReason,
  });

  final String id;
  final String email;
  final UserRole role;
  final String status;

  /// Whether this user can hide or delete other people's community posts.
  /// Independent of [role] — a player, club or coach can moderate without
  /// being an admin.
  final bool isModerator;

  /// When a suspension ends. Null while the account is active, and also
  /// null for a *permanent* suspension — so read it together with [status]:
  /// suspended + null means "forever".
  final DateTime? suspendedUntil;

  /// The admin's own note about why. Never shown to the suspended user.
  final String? suspensionReason;

  bool get isSuspended => status == 'SUSPENDED';

  /// A suspension with no end date — the account does not come back on its
  /// own.
  bool get isPermanentlySuspended => isSuspended && suspendedUntil == null;
}

/// The fixed suspension terms the dashboard offers. The wire values match
/// the backend's `SuspensionDuration` enum.
enum SuspensionDuration {
  oneMonth('1M'),
  threeMonths('3M'),
  oneYear('1Y'),
  permanent('PERMANENT');

  const SuspensionDuration(this.wireValue);

  final String wireValue;
}
