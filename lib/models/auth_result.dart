import 'auth_user.dart';

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data =
        json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;

    final Map<String, dynamic> userJson =
        (data['user'] ?? data['usuario']) is Map<String, dynamic>
            ? (data['user'] ?? data['usuario']) as Map<String, dynamic>
            : data;

    return AuthResult(
      accessToken:
          (data['access_token'] ?? data['accessToken'] ?? data['token'] ?? '').toString(),
      refreshToken: (data['refresh_token'] ?? data['refreshToken'] ?? '').toString(),
      user: AuthUser.fromJson(userJson),
    );
  }
}
