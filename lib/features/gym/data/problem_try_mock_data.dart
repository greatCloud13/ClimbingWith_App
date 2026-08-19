import 'dart:math';

/// 게스트 체험 모드용 홀드 갯수(목업). `GET /api/problem/{id}/detail`이 비로그인
/// 요청에 403을 내려 실제 holdCount를 못 받을 때만 쓴다 — 문제 id 기준 고정값.
int mockHoldCount(int problemId) => 10 + Random(problemId).nextInt(11);

/// 홀드 순번(1-based) → 그 지점에서 떨어진 사람 수(목업). 커뮤니티 낙하 분포
/// API가 아직 없어 문제 id + 실제 홀드 갯수를 시드로 고정 생성한다.
Map<int, int> mockCommunityFallCounts(int problemId, int holdCount) {
  if (holdCount <= 1) return const {};
  final rnd = Random(problemId);
  final counts = <int, int>{};
  for (var i = 1; i < holdCount; i++) {
    final base = rnd.nextInt(12);
    if (base > 3) counts[i] = base;
  }
  // 크럭스(가장 많이 떨어지는 구간)를 상단부 쪽에 하나 도드라지게 만든다.
  final cruxHold = (holdCount * 0.6).round().clamp(1, holdCount - 1);
  counts[cruxHold] = 18 + rnd.nextInt(10);
  return counts;
}
