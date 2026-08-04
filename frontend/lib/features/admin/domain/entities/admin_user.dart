import '../../../auth/domain/entities/user_role.dart';

class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
  });

  final String id;
  final String email;
  final UserRole role;
  final String status;
}
