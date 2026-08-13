/// GET /api/problem/{id}/dropPointStats 응답 — 커뮤니티 낙하 지점 분포(홀드
/// 순번별로 몇 명이 그 지점에서 떨어졌는지). 루트 토포 히트맵에 쓴다.
class DropPointStats {
  const DropPointStats({
    required this.problemId,
    required this.holdCount,
    required this.totalUserCount,
    required this.distribution,
  });

  final int problemId;
  final int holdCount;
  final int totalUserCount;

  /// 홀드 순번(1-based) → 그 지점에서 떨어진 사람 수.
  final Map<int, int> distribution;

  factory DropPointStats.fromJson(Map<String, dynamic> json) => DropPointStats(
    problemId: json['problemId'] as int,
    holdCount: json['holdCount'] as int? ?? 0,
    totalUserCount: (json['totalUserCount'] as num?)?.toInt() ?? 0,
    distribution: {
      for (final e in (json['distribution'] as List<dynamic>? ?? const []))
        (e as Map<String, dynamic>)['dropPoint'] as int: (e['count'] as num).toInt(),
    },
  );
}
