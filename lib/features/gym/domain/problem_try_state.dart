import 'problem_try_log.dart';

/// 문제 상세조회 화면의 트라이 인터랙션 상태 — 실제 서버 데이터(홀드 갯수,
/// 내 최고 도달 지점 등)는 [GymProblemDetail](gym_problem_detail.dart)에서
/// 오고, 여기서는 '트라이 시작'/'여기서 떨어짐' 조작 중의 화면 상태와 이번
/// 세션에 실제로 POST해서 만든 트라이 기록만 들고 있는다. 문제 단위로 과거
/// 기록을 조회하는 API가 아직 없어(reports/2026-08-10_problem-detail-stats-api-request.md
/// 참고) 세션 밖 기록은 보여줄 수 없다.
class ProblemTryState {
  const ProblemTryState({this.sessionHistory = const [], this.isTryActive = false, this.pendingHoldIndex});

  /// 이번 세션에 실제로 서버에 기록(POST /api/problemTryLog)한 트라이 — 최신순.
  final List<ProblemTryLog> sessionHistory;

  /// 트라이 진행 중 여부 — '트라이 시작'을 누르면 true, '여기서 떨어짐'/'취소'로 false.
  final bool isTryActive;

  /// 진행 중인 트라이에서 루트를 탭해 고른(아직 확정 전) 지점.
  final int? pendingHoldIndex;

  int? get lastSessionFallHoldIndex => sessionHistory.isEmpty ? null : sessionHistory.first.dropPoint;
}
