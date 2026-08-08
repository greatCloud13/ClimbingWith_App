import 'package:dio/dio.dart';
import '../domain/home_gym_card.dart';

class HomeApi {
  HomeApi(this._dio);

  final Dio _dio;

  /// GET /api/home — 토큰으로 사용자를 식별하므로 별도 파라미터 없음.
  Future<List<HomeGymCard>> fetchHomeGymCards() async {
    final res = await _dio.get('/api/home');
    final data = res.data as Map<String, dynamic>;
    final list = data['gymCardList'] as List<dynamic>? ?? [];
    return list
        .map((e) => HomeGymCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
