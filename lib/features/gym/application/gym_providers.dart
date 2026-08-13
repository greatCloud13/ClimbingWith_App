import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_providers.dart';
import '../data/bookmark_api.dart';
import '../data/gym_api.dart';
import '../domain/gym_detail.dart';
import '../domain/gym_level.dart';
import '../domain/gym_problem.dart';
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
