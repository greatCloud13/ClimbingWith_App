import 'dart:math';

/// 게스트 체험 모드용 홀드 갯수(목업). `GET /api/problem/{id}/detail`이 비로그인
/// 요청에 403을 내려 실제 holdCount를 못 받을 때만 쓴다 — 문제 id 기준 고정값.
int mockHoldCount(int problemId) => 10 + Random(problemId).nextInt(11);

/// 점장님이 홀드별로 남길 법한 공략 팁 목업 문구 풀 — 매니저용 작성 기능이
/// 아직 없어 홀드 순번 기준으로 고정 생성한다.
const _managerTipPool = [
  '오른손은 오픈그립으로 잡는 게 편해요.',
  '왼발을 홀드 안쪽으로 밀어 넣으면 밸런스가 잘 잡혀요.',
  '파워보다 타이밍이 중요한 구간이에요 — 데드포인트로 넘어가보세요.',
  '홀드가 미끄러운 편이니 초크를 충분히 발라주세요.',
  '몸을 벽 쪽으로 붙이면 다음 홀드가 더 가깝게 느껴질 거예요.',
  '스태틱하게 천천히 이동하는 게 좋은 구간이에요.',
  '발 위치를 한 칸 낮춰서 시작하면 리치가 편해져요.',
];

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

/// 홀드 순번(1-based) → 점장님 팁(목업). 모든 홀드에 있는 건 아니다.
Map<int, String> mockManagerTips(int problemId, int holdCount) {
  // 낙하 분포 시드와 겹치지 않도록 값을 섞어서 별도 시드로 쓴다.
  final rnd = Random(problemId ^ 0x5bd1e995);
  final tips = <int, String>{};
  for (var i = 1; i <= holdCount; i++) {
    if (rnd.nextDouble() < 0.35) {
      tips[i] = _managerTipPool[rnd.nextInt(_managerTipPool.length)];
    }
  }
  return tips;
}
