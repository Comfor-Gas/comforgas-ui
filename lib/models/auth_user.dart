import 'user_role.dart';

class AuthUser {
  final String id;
  final String email;
  final String? fullName;
  final UserRole role;

  const AuthUser({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final roleValue = json['rol'] ??
        json['role'] ??
        json['rol_id'] ??
        json['role_id'] ??
        json['rolId'];

    return AuthUser(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      fullName: (json['full_name'] ?? json['fullName']) as String?,
      role: UserRoleMapper.fromValue(roleValue),
    );
  }
}
