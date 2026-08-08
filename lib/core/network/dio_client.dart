import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'token_storage.dart';

/// 인증 토큰을 자동으로 붙이고, 401 응답 시 로그아웃 콜백을 호출하는
/// 공용 Dio 인스턴스. 토큰 만료시간이 아직 서버에서 확정되지 않았으므로
/// 만료를 미리 계산하지 않고, 서버가 401을 내려줄 때 반응적으로 처리한다.
class DioClient {
  DioClient({required TokenStorage tokenStorage, required this.onUnauthorized})
      : _tokenStorage = tokenStorage {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _tokenStorage.clearSession();
            onUnauthorized();
          }
          handler.next(error);
        },
      ),
    );
  }

  final TokenStorage _tokenStorage;
  final void Function() onUnauthorized;
  late final Dio dio;
}
