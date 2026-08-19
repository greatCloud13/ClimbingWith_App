import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/application/auth_state.dart';
import '../data/bookmark_api.dart';
import '../data/gym_api.dart';
import '../data/problem_try_mock_data.dart';
import '../domain/clear_record.dart';
import '../domain/drop_point_stats.dart';
import '../domain/gym_detail.dart';
import '../domain/gym_level.dart';
import '../domain/gym_problem.dart';
import '../domain/gym_problem_detail.dart';
import '../domain/problem_try_log.dart';
import '../domain/sector_detail.dart';

final Provider<GymApi> gymApiProvider = Provider<GymApi>(
  (ref) => GymApi(ref.watch(dioClientProvider).dio),
);

/// 실제 gymId(정수)로 GET /api/gym/{id}를 호출한다. 목업 암장(문자열 id)에는 쓰이지 않는다.
final gymDetailProvider = FutureProvider.family<GymDetail, int>(
  (ref, id) => ref.watch(gymApiProvider).fetchGymDetail(id),
);

/// GET /api/sector/{id} — 섹터 상세 + 세팅 기록.
final sectorDetailProvider = FutureProvider.family<SectorDetail, int>(
  (ref, sectorId) => ref.watch(gymApiProvider).fetchSectorDetail(sectorId),
);

/// GET /api/problem/setting/{id} — 세팅에 속한 문제(루트) 목록.
final problemsBySettingProvider = FutureProvider.family<List<GymProblem>, int>(
  (ref, settingId) => ref.watch(gymApiProvider).fetchProblemsBySetting(settingId),
);

/// GET /api/problem/{id}/detail — 문제 상세조회 화면 전용(홀드 갯수, 내 최고
/// 도달 지점 등 목록 API에 없는 필드 포함). 이 API는 비로그인 요청에 403을
/// 내려주므로(로그인 필요), 게스트는 공개 정보(`GET /api/problem/{id}`)로
/// 구성한 "체험 모드" 데이터로 대체해 화면 자체는 계속 볼 수 있게 한다.
final gymProblemDetailProvider = FutureProvider.family<GymProblemDetail, int>((ref, problemId) async {
  final api = ref.watch(gymApiProvider);
  try {
    return await api.fetchProblemDetail(problemId);
  } on DioException catch (e) {
    if (e.response?.statusCode != 403) rethrow;
    final basic = await api.fetchProblem(problemId);
    return GymProblemDetail(
      id: basic.id,
      settingId: basic.settingId,
      title: basic.title,
      problemType: basic.problemType,
      gymLevel: basic.gymLevel,
      holdCount: mockHoldCount(basic.id),
      myTryCount: 0,
      clearCount: basic.clearUserCount,
      levelId: basic.levelId,
      colorCode: basic.colorCode,
      description: basic.description,
      evaluation: basic.evaluation,
      isGuestPreview: true,
    );
  }
});

/// GET /api/problem/{id}/dropPointStats — 커뮤니티 낙하 지점 분포(루트 토포
/// 히트맵). 게스트 체험 모드에서는 holdCount 자체가 목업이라 실데이터와
/// 안 맞을 수 있어 쓰지 않는다([problem_detail_screen.dart]에서 분기).
final dropPointStatsProvider = FutureProvider.family<DropPointStats, int>(
  (ref, problemId) => ref.watch(gymApiProvider).fetchDropPointStats(problemId),
);

/// 로그인 사용자의 이 문제에 대한 과거 트라이 기록 — `GET /api/problemTryLog/user/{userId}`에는
/// 문제별 필터가 없어 클라이언트에서 problemId로 걸러 쓴다(최근 100건 안에서만
/// 찾으므로, 트라이가 아주 많은 사용자는 오래된 기록을 놓칠 수 있다). userId를
/// 모르면(구 버전 세션 등) 빈 목록을 반환 — 화면에서는 이 경우 세션 로컬 기록으로 대체한다.
final myProblemTryLogsProvider = FutureProvider.family<List<ProblemTryLog>, int>((ref, problemId) async {
  final authState = ref.watch(authControllerProvider);
  if (authState is! AuthAuthenticated) return const [];
  final userId = authState.user.userId;
  if (userId == null) return const [];
  final page = await ref.watch(gymApiProvider).fetchTryLogsByUser(userId, size: 100);
  return page.logs.where((log) => log.problemId == problemId).toList();
});

/// user+problem 기준 진행 중인(isClear=false) 완등 기록 — "시작일자" 표시와
/// '트라이 시작'의 기존 기록 재사용이 함께 쓰는 단일 소스([problem_try_providers.dart]).
/// 새로 만들거나 완등 처리하면 무효화해 최신 상태를 반영한다. userId를 모르면
/// (게스트, 구 버전 세션) 항상 null — 화면에서는 "미시작"으로 표시한다.
final inProgressClearRecordProvider = FutureProvider.family<ClearRecord?, int>((ref, problemId) async {
  final authState = ref.watch(authControllerProvider);
  if (authState is! AuthAuthenticated) return null;
  final userId = authState.user.userId;
  if (userId == null) return null;
  return ref.watch(gymApiProvider).fetchInProgressClearRecord(userId: userId, problemId: problemId);
});

/// GET /api/level/gym/{gymId} — 암장 난이도(레벨) 목록. 문제 등록/수정 폼의
/// 드롭다운에서 쓴다.
final levelsByGymProvider = FutureProvider.family<List<GymLevel>, int>(
  (ref, gymId) => ref.watch(gymApiProvider).fetchLevelsByGym(gymId),
);

final Provider<BookmarkApi> bookmarkApiProvider = Provider<BookmarkApi>(
  (ref) => BookmarkApi(ref.watch(dioClientProvider).dio),
);

/// 이번 세션 중 앱에서 직접 등록한 gymId → 북마크 id 매핑.
/// 조회 API(GET /api/home 등)는 북마크 id를 내려주지 않아서, 해제(DELETE)에
/// 필요한 id를 세션 동안만이라도 기억해두는 용도 — 앱을 새로 켜서 이미
/// 즐겨찾기된 상태로 들어온 암장은 이 맵에 없어 해제가 안 될 수 있다
/// (reports/ 참고).
final StateProvider<Map<int, int>> bookmarkIdMapProvider =
    StateProvider<Map<int, int>>((ref) => {});
