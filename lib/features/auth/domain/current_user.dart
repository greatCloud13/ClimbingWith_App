class CurrentUser {
  const CurrentUser({
    this.userId,
    required this.username,
    required this.nickname,
    required this.role,
    this.managedGymId,
  });

  /// 로그인 사용자의 숫자 id — 2026-08-18부터 로그인 응답에 포함됨. 그 이전에
  /// 저장된 세션(로컬 캐시)에는 없을 수 있어 nullable로 둔다 — 이 값이 필요한
  /// 기능(트라이 기록 이력, 완등 진행 중 기록 조회 등)은 null이면 재로그인해야 동작한다.
  final int? userId;
  final String username;
  final String nickname;
  final String role;
  final int? managedGymId;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'username': username,
    'nickname': nickname,
    'role': role,
    'managedGymId': managedGymId,
  };

  factory CurrentUser.fromJson(Map<String, dynamic> json) => CurrentUser(
    userId: json['userId'] as int?,
    username: json['username'] as String,
    nickname: json['nickname'] as String,
    role: json['role'] as String,
    managedGymId: json['managedGymId'] as int?,
  );
}
