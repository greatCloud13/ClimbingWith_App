class SignUpRequest {
  const SignUpRequest({
    required this.username,
    required this.nickname,
    required this.email,
    required this.password,
  });

  final String username;
  final String nickname;
  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'username': username,
        'nickname': nickname,
        'email': email,
        'password': password,
      };
}

class LoginRequest {
  const LoginRequest({required this.username, required this.password});

  final String username;
  final String password;

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };
}

/// POST /api/auth/login 응답.
/// 현재는 AccessToken만 내려온다 (RefreshToken은 추후 추가 예정).
/// 토큰 만료시간 필드는 아직 확정되지 않아 파싱하지 않는다 — 만료는
/// 401 응답을 받았을 때 반응적으로 로그아웃 처리한다.
class LoginResponse {
  const LoginResponse({
    required this.token,
    required this.username,
    required this.role,
    required this.nickname,
    this.managedGymId,
  });

  final String token;
  final String username;
  final String role;
  final String nickname;
  final int? managedGymId;

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        token: json['token'] as String,
        username: json['username'] as String,
        role: json['role'] as String,
        nickname: json['nickname'] as String,
        managedGymId: json['managedGymId'] as int?,
      );
}
