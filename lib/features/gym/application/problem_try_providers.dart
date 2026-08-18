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
///
/// '트라이 시작'은 `GET /api/clearRecord/user/{userId}/problem/{problemId}/inProgress`로
/// 기존에 진행 중이던(isClear=false) 완등 기록이 있는지 먼저 확인하고, 없으면
/// `POST /api/clearRecord`로 새로 만든다 — userId를 모르면(구 버전 세션 등)
/// 조회를 건너뛰고 바로 생성한다. 완등(dropPoint == holdCount)으로 기록하면
/// `PATCH /api/clearRecord/{id}/clear`로 완등 처리하고 다음 트라이를 위해
/// 다시 null로 돌아간다. 이 기록 조회/생성/완등 처리는 부가 기능이라 실패해도
/// problemTryLog 기록 자체는 계속 진행한다.
class ProblemTryNotifier extends StateNotifier<ProblemTryState> {
  ProblemTryNotifier(this._ref, this._problemId) : super(const ProblemTryState());

  final Ref _ref;
  final int _problemId;

  bool get _isAuthenticated => _ref.read(authControllerProvider) is AuthAuthenticated;

  Future<void> startTry() async {
    if (state.isTryActive) return;
    state = ProblemTryState(
      sessionHistory: state.sessionHistory,
      activeClearRecordId: state.activeClearRecordId,
      isTryActive: true,
    );

    if (state.activeClearRecordId != null || !_isAuthenticated) return;
    final authState = _ref.read(authControllerProvider);
    final userId = authState is AuthAuthenticated ? authState.user.userId : null;
    try {
      final api = _ref.read(gymApiProvider);
      final existing = userId == null
          ? null
          : await api.fetchInProgressClearRecord(userId: userId, problemId: _problemId);
      final record = existing ?? await api.createClearRecord(problemId: _problemId);
      state = ProblemTryState(
        sessionHistory: state.sessionHistory,
        activeClearRecordId: record.id,
        isTryActive: state.isTryActive,
        pendingHoldIndex: state.pendingHoldIndex,
      );
    } catch (_) {
      // 완등 기록 조회/생성은 부가 기능 — 실패해도 트라이 자체는 계속 진행.
    }
  }

  void selectHold(int holdIndex) {
    if (!state.isTryActive) return;
    state = ProblemTryState(
      sessionHistory: state.sessionHistory,
      activeClearRecordId: state.activeClearRecordId,
      isTryActive: true,
      pendingHoldIndex: holdIndex,
    );
  }

  void cancelTry() {
    state = ProblemTryState(sessionHistory: state.sessionHistory, activeClearRecordId: state.activeClearRecordId);
  }

  /// '어떤 홀드였나요?' 모달에서 '기록하기'를 누르면 호출된다. [isClear]는 이
  /// 트라이가 완등(최상단 홀드)인지. 성공하면 true.
  Future<bool> fellHere({String? memo, required bool isClear}) async {
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
      final api = _ref.read(gymApiProvider);
      final log = await api.createTryLog(problemId: _problemId, dropPoint: pending, memo: memo);

      var clearRecordId = state.activeClearRecordId;
      if (isClear && clearRecordId != null) {
        try {
          await api.clearProblemRecord(clearRecordId);
          clearRecordId = null; // 완등 처리 완료 — 다음 트라이는 새 기록으로 시작
        } catch (_) {
          // 완등 처리 실패해도 problemTryLog 기록 자체는 이미 성공했으니 무시.
        }
      }

      state = ProblemTryState(sessionHistory: [log, ...state.sessionHistory], activeClearRecordId: clearRecordId);
      _ref.invalidate(gymProblemDetailProvider(_problemId));
      _ref.invalidate(myProblemTryLogsProvider(_problemId));
      return true;
    } catch (_) {
      state = ProblemTryState(
        sessionHistory: state.sessionHistory,
        activeClearRecordId: state.activeClearRecordId,
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
