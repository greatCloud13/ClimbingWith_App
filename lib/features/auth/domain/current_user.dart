class CurrentUser {
  const CurrentUser({
    required this.username,
    required this.nickname,
    required this.role,
    this.managedGymId,
  });

  final String username;
  final String nickname;
  final String role;
  final int? managedGymId;

  Map<String, dynamic> toJson() => {
        'username': username,
        'nickname': nickname,
        'role': role,
        'managedGymId': managedGymId,
      };

  factory CurrentUser.fromJson(Map<String, dynamic> json) => CurrentUser(
        username: json['username'] as String,
        nickname: json['nickname'] as String,
        role: json['role'] as String,
        managedGymId: json['managedGymId'] as int?,
      );
}
