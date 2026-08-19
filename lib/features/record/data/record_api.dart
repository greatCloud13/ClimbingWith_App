import 'package:dio/dio.dart';
import '../domain/recent_clear_record.dart';

class RecordApi {
  RecordApi(this._dio);

  final Dio _dio;

  /// 사용자 기준 완등 기록 목록 — 최신 일자순 정렬.
  Future<RecentClearRecordPage> fetchRecentClearRecords(int userId, {int page = 0, int size = 10}) async {
    final res = await _dio.get(
      '/api/clearRecord/user/$userId',
      queryParameters: {'page': page, 'size': size},
    );
    return RecentClearRecordPage.fromJson(res.data as Map<String, dynamic>);
  }
}
