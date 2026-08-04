import '../../../auth/domain/entities/user_role.dart';
import '../../domain/entities/admin_user.dart';

extension AdminUserModel on AdminUser {
  static AdminUser fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      email: json['email'] as String,
      role: UserRole.fromWire(json['role'] as String),
      status: json['status'] as String,
    );
  }
}
