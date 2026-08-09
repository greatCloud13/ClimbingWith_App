import 'package:dio/dio.dart';

class BookmarkApi {
  BookmarkApi(this._dio);

  final Dio _dio;

  /// POST /api/bookmark/{gymId} — 반환되는 id는 북마크(즐겨찾기) 자체의 id.
  /// gymId가 아니라 이 id로 나중에 해제(DELETE)해야 한다.
  Future<int> createBookmark(int gymId) async {
    final res = await _dio.post('/api/bookmark/$gymId');
    return (res.data as Map<String, dynamic>)['id'] as int;
  }

  Future<void> deleteBookmark(int bookmarkId) async {
    await _dio.delete('/api/bookmark/$bookmarkId');
  }
}
