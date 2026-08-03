import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_role.dart';

extension AppUserModel on AppUser {
  static AppUser fromJson(Map<String, dynamic> json) {
    final roleWire = json['role'] as String;
    try {
      return AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        role: UserRole.fromWire(roleWire),
        status: json['status'] as String,
      );
    } on ArgumentError {
      throw AppException('This account type is not supported in this app.');
    }
  }
}
