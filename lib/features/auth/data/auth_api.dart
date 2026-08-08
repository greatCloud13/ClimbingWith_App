import 'package:dio/dio.dart';
import '../../../core/network/api_exception.dart';
import 'auth_models.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<String> signUp(SignUpRequest request) async {
    try {
      final res = await _dio.post('/api/auth/signup', data: request.toJson());
      return (res.data as Map<String, dynamic>)['message'] as String? ??
          '회원가입이 완료되었습니다.';
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final res = await _dio.post('/api/auth/login', data: request.toJson());
      return LoginResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
