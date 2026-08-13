import 'package:dio/dio.dart';
import '../../../core/network/api_exception.dart';
import '../domain/climbing_discipline.dart';
import '../domain/gym_detail.dart';
import '../domain/climbing_setting.dart';
import '../domain/gym_post.dart';
import '../domain/gym_problem.dart';
import '../domain/gym_level.dart';
import '../domain/sector.dart';
import '../domain/sector_detail.dart';

class GymApi {
  GymApi(this._dio);

  final Dio _dio;

  Future<GymDetail> fetchGymDetail(int id) async {
    final res = await _dio.get('/api/gym/$id');
    return GymDetail.fromApiJson(res.data as Map<String, dynamic>);
  }

  /// 전체 게시글(모든 postType 혼합) — 게시판 "전체" 탭에서 사용.
  Future<GymPostPage> fetchGymPosts(
    int gymId, {
    int page = 0,
    int size = 20,
  }) async {
    final res = await _dio.get(
      '/api/post/gym/$gymId',
      queryParameters: {'page': page, 'size': size, 'sort': 'createdAt,desc'},
    );
    return GymPostPage.fromJson(res.data as Map<String, dynamic>);
  }

  /// postType으로 서버에서 필터링된 게시글 — 게시판 태그 필터에서 사용.
  Future<GymPostPage> fetchGymPostsByType(
    int gymId,
    String postType, {
    int page = 0,
    int size = 20,
  }) async {
    final res = await _dio.get(
      '/api/post/gym/$gymId/posttype/$postType',
      queryParameters: {'page': page, 'size': size, 'sort': 'createdAt,desc'},
    );
    return GymPostPage.fromJson(res.data as Map<String, dynamic>);
  }

  /// 게시글 상세 조회 — 수정 폼에 기존 내용을 채울 때도 사용.
  Future<GymPostDetail> fetchPostDetail(int postId) async {
    final res = await _dio.get('/api/post/$postId');
    return GymPostDetail.fromJson(res.data as Map<String, dynamic>);
  }

  /// 신규 게시글 작성 — gymId는 경로에 없고 인증된 GYM_MANAGER의 관리 암장으로
  /// 서버에서 자동 결정된다.
  Future<GymPostDetail> createPost({
    required String title,
    required String postType,
    required String content,
  }) async {
    try {
      final res = await _dio.post(
        '/api/post',
        data: {'title': title, 'postType': postType, 'content': content},
      );
      return GymPostDetail.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<GymPostDetail> updatePost(
    int postId, {
    required String title,
    required String postType,
    required String content,
  }) async {
    try {
      final res = await _dio.put(
        '/api/post/$postId',
        data: {'title': title, 'postType': postType, 'content': content},
      );
      return GymPostDetail.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deletePost(int postId) async {
    try {
      await _dio.delete('/api/post/$postId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 섹터 상세 + 세팅 기록 목록. 응답이 `{success, data, error}`로 감싸져 있어
  /// `data`만 꺼내 쓴다.
  Future<SectorDetail> fetchSectorDetail(int sectorId) async {
    final res = await _dio.get('/api/sector/$sectorId');
    final body = res.data as Map<String, dynamic>;
    return SectorDetail.fromApiJson(body['data'] as Map<String, dynamic>);
  }

  /// 신규 섹터 생성. 응답은 `{success, data, error}`로 감싸져 있어 `data`만 꺼내 쓴다.
  /// 삭제/비활성화 API는 아직 없음 — 추가되면 여기에 메서드를 더한다.
  Future<Sector> createSector({
    required int gymId,
    required String sectorName,
    String? description,
    required ClimbingDiscipline discipline,
  }) async {
    try {
      final res = await _dio.post(
        '/api/sector',
        data: {
          'gymId': gymId,
          'sectorName': sectorName,
          if (description != null && description.isNotEmpty) 'description': description,
        },
      );
      final body = res.data as Map<String, dynamic>;
      return Sector.fromApiJson(body['data'] as Map<String, dynamic>, discipline: discipline);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 섹터 정보 수정(이름/설명/세팅일/다음 세팅 예정일).
  Future<Sector> updateSector({
    required int sectorId,
    required String sectorName,
    String? description,
    String? settingDate,
    String? nextSettingDate,
    required ClimbingDiscipline discipline,
  }) async {
    try {
      final res = await _dio.put(
        '/api/sector/$sectorId',
        data: {
          'sectorName': sectorName,
          if (description != null && description.isNotEmpty) 'description': description,
          'settingDate': ?settingDate,
          'nextSettingDate': ?nextSettingDate,
        },
      );
      final body = res.data as Map<String, dynamic>;
      return Sector.fromApiJson(body['data'] as Map<String, dynamic>, discipline: discipline);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 새 세팅 생성 — 세부정보(기간) 없이 섹터/암장만으로 생성하고, 이후
  /// [updateSetting]으로 기간을 채운다.
  Future<ClimbingSetting> createSetting({
    required int sectorId,
    required int gymId,
  }) async {
    try {
      final res = await _dio.post(
        '/api/setting',
        data: {'sectorId': sectorId, 'gymId': gymId},
      );
      final body = res.data as Map<String, dynamic>;
      return ClimbingSetting.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 세팅 일자/기간 수정. `endDate`가 없으면(진행 중) 보내지 않는다.
  Future<ClimbingSetting> updateSetting({
    required int settingId,
    required String settingDate,
    required String startDate,
    String? endDate,
  }) async {
    try {
      final res = await _dio.put(
        '/api/setting/$settingId',
        data: {
          'settingDate': settingDate,
          'startDate': startDate,
          'endDate': ?endDate,
        },
      );
      final body = res.data as Map<String, dynamic>;
      return ClimbingSetting.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteSetting(int settingId) async {
    try {
      await _dio.delete('/api/setting/$settingId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ClimbingSetting> disableSetting(int settingId) async {
    try {
      final res = await _dio.patch('/api/setting/$settingId/disable');
      final body = res.data as Map<String, dynamic>;
      return ClimbingSetting.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ClimbingSetting> activateSetting(int settingId) async {
    try {
      final res = await _dio.patch('/api/setting/$settingId/active');
      final body = res.data as Map<String, dynamic>;
      return ClimbingSetting.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 세팅에 속한 문제(루트) 목록.
  Future<List<GymProblem>> fetchProblemsBySetting(int settingId) async {
    final res = await _dio.get('/api/problem/setting/$settingId');
    return (res.data as List<dynamic>)
        .map((e) => GymProblem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 신규 문제 등록. `gymLevelId`는 [fetchLevelsByGym]으로 조회한 난이도 단계의 id.
  Future<GymProblem> createProblem({
    required int settingId,
    required String title,
    required String problemType,
    required int gymLevelId,
    String? description,
  }) async {
    try {
      final res = await _dio.post(
        '/api/problem',
        data: {
          'settingId': settingId,
          'title': title,
          'problemType': problemType,
          'gymLevelId': gymLevelId,
          if (description != null && description.isNotEmpty) 'description': description,
        },
      );
      return GymProblem.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<GymProblem> updateProblem({
    required int problemId,
    required int settingId,
    required String title,
    required String problemType,
    required int gymLevelId,
    String? description,
  }) async {
    try {
      final res = await _dio.put(
        '/api/problem/$problemId',
        data: {
          'settingId': settingId,
          'title': title,
          'problemType': problemType,
          'gymLevelId': gymLevelId,
          if (description != null && description.isNotEmpty) 'description': description,
        },
      );
      return GymProblem.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteProblem(int id) async {
    try {
      await _dio.delete('/api/problem/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 암장의 난이도(레벨) 목록. 문제 등록/수정 폼의 난이도 드롭다운에 쓴다.
  Future<List<GymLevel>> fetchLevelsByGym(int gymId) async {
    final res = await _dio.get('/api/level/gym/$gymId');
    return (res.data as List<dynamic>)
        .map((e) => GymLevel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 새 난이도 등록 — 문제 등록 폼에서 해당 종목(climbType)에 등록된 난이도가
  /// 하나도 없을 때 바로 만들 수 있도록 제공.
  Future<GymLevel> createLevel({
    required int gymId,
    required String levelName,
    required int displayOrder,
    String? colorCode,
    String? description,
    required String climbType,
  }) async {
    try {
      final res = await _dio.post(
        '/api/level',
        data: {
          'gymId': gymId,
          'levelName': levelName,
          'displayOrder': displayOrder,
          'climbType': climbType,
          if (colorCode != null && colorCode.isNotEmpty) 'colorCode': colorCode,
          if (description != null && description.isNotEmpty) 'description': description,
        },
      );
      return GymLevel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 난이도 정보 수정(이름/색상/표시순서/설명/종목).
  Future<GymLevel> updateLevel({
    required int levelId,
    required String levelName,
    required int displayOrder,
    String? colorCode,
    String? description,
    required String climbType,
  }) async {
    try {
      final res = await _dio.put(
        '/api/level/$levelId',
        data: {
          'levelName': levelName,
          'displayOrder': displayOrder,
          'climbType': climbType,
          if (colorCode != null && colorCode.isNotEmpty) 'colorCode': colorCode,
          if (description != null && description.isNotEmpty) 'description': description,
        },
      );
      return GymLevel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteLevel(int id) async {
    try {
      await _dio.delete('/api/level/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
