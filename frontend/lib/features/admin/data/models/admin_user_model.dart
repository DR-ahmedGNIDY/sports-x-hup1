import '../../../auth/domain/entities/user_role.dart';
import '../../domain/entities/admin_user.dart';

extension AdminUserModel on AdminUser {
  static AdminUser fromJson(Map<String, dynamic> json) {
    final suspendedUntil = json['suspendedUntil'] as String?;
    return AdminUser(
      id: json['id'] as String,
      // A club-created player account has a phone instead of an email, so
      // fall back rather than crashing the whole admin list on one row.
      email: json['email'] as String? ?? json['phone'] as String? ?? '—',
      role: UserRole.fromWire(json['role'] as String),
      status: json['status'] as String,
      isModerator: json['isModerator'] as bool? ?? false,
      // Absent for an active account and for a permanent suspension alike
      // — see AdminUser.suspendedUntil.
      suspendedUntil: suspendedUntil == null
          ? null
          : DateTime.parse(suspendedUntil).toLocal(),
      suspensionReason: json['suspensionReason'] as String?,
    );
  }
}
