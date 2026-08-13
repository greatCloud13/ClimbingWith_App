import 'package:dio/dio.dart';
import '../../../core/network/api_exception.dart';
import '../domain/gym_detail.dart';
import '../domain/gym_post.dart';

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
}
