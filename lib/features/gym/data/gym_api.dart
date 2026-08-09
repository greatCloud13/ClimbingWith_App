import 'package:dio/dio.dart';
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
}
