import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'gym_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/application/auth_state.dart';
import '../domain/problem_try_log.dart';
import '../domain/problem_try_state.dart';

/// 문제별 트라이 인터랙션 상태. 로그인 사용자는 '트라이 시작'/'여기서 떨어짐'을
/// 실제 POST /api/problemTryLog 호출로 반영한다 — 성공하면 이번 세션 기록 목록
/// 맨 앞에 추가하고, 문제 상세([gymProblemDetailProvider])를 무효화해 서버가
/// 다시 계산한 내 최고 도달 지점(myBestDropPoint) 등을 반영한다. **게스트는
/// 이 API가 403이라 저장할 수 없어**, 서버 호출 없이 세션 로컬에만 기록을
/// 남기는 "체험 모드"로 동작한다(화면을 나가면 사라짐).
class ProblemTryNotifier extends StateNotifier<ProblemTryState> {
  ProblemTryNotifier(this._ref, this._problemId) : super(const ProblemTryState());

  final Ref _ref;
  final int _problemId;

  bool get _isAuthenticated => _ref.read(authControllerProvider) is AuthAuthenticated;

  void startTry() {
    if (state.isTryActive) return;
    state = ProblemTryState(sessionHistory: state.sessionHistory, isTryActive: true);
  }

  void selectHold(int holdIndex) {
    if (!state.isTryActive) return;
    state = ProblemTryState(
      sessionHistory: state.sessionHistory,
      isTryActive: true,
      pendingHoldIndex: holdIndex,
    );
  }

  void cancelTry() {
    state = ProblemTryState(sessionHistory: state.sessionHistory);
  }

  /// '어떤 홀드였나요?' 모달에서 '기록하기'를 누르면 호출된다. 성공하면 true.
  Future<bool> fellHere({String? memo}) async {
    final pending = state.pendingHoldIndex;
    if (!state.isTryActive || pending == null) return false;

    if (!_isAuthenticated) {
      // 게스트 체험 모드 — 서버에 저장하지 않고 세션에만 남긴다.
      final localLog = ProblemTryLog(
        id: -DateTime.now().microsecondsSinceEpoch,
        userId: 0,
        problemId: _problemId,
        tryDate: DateTime.now().toIso8601String(),
        dropPoint: pending,
        memo: memo,
        isLocalOnly: true,
      );
      state = ProblemTryState(sessionHistory: [localLog, ...state.sessionHistory]);
      return true;
    }

    try {
      final log = await _ref
          .read(gymApiProvider)
          .createTryLog(problemId: _problemId, dropPoint: pending, memo: memo);
      state = ProblemTryState(sessionHistory: [log, ...state.sessionHistory]);
      _ref.invalidate(gymProblemDetailProvider(_problemId));
      return true;
    } catch (_) {
      state = ProblemTryState(
        sessionHistory: state.sessionHistory,
        isTryActive: true,
        pendingHoldIndex: pending,
      );
      return false;
    }
  }
}

final problemTryProvider = StateNotifierProvider.family<ProblemTryNotifier, ProblemTryState, int>(
  (ref, problemId) => ProblemTryNotifier(ref, problemId),
);
