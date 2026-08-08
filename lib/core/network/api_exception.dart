import 'package:dio/dio.dart';

/// 서버 에러 응답을 사용자에게 보여줄 메시지로 정규화한다.
///
/// 실제 백엔드 응답을 확인해 확정된 포맷: `{success, data, error: {code, message}}`.
/// 혹시 모를 다른 형태(순수 `message`, `errors[].defaultMessage`)도 함께
/// 시도해 하위호환성을 유지하고, 모두 실패하면 상태코드 기반 기본 메시지로
/// 대체한다.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errorCode});

  final String message;
  final int? statusCode;
  final String? errorCode;

  factory ApiException.fromDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        final message = error['message'] as String?;
        if (message != null && message.isNotEmpty) {
          return ApiException(message, statusCode: statusCode, errorCode: error['code'] as String?);
        }
      }

      final message = data['message'] as String? ??
          (error is String ? error : null) ??
          _firstValidationMessage(data);
      if (message != null && message.isNotEmpty) {
        return ApiException(message, statusCode: statusCode);
      }
    }

    return ApiException(_fallbackMessage(statusCode, e), statusCode: statusCode);
  }

  static String? _firstValidationMessage(Map<String, dynamic> data) {
    final errors = data['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is Map<String, dynamic>) {
        return first['defaultMessage'] as String? ?? first['message'] as String?;
      }
    }
    return null;
  }

  static String _fallbackMessage(int? statusCode, DioException e) {
    switch (statusCode) {
      case 400:
        return '입력값을 다시 확인해주세요.';
      case 401:
        return '아이디 또는 비밀번호가 올바르지 않습니다.';
      case 409:
        return '이미 사용 중인 아이디 또는 이메일입니다.';
      case null:
        return '서버에 연결할 수 없습니다. 네트워크 상태를 확인해주세요.';
      default:
        return '알 수 없는 오류가 발생했습니다. ($statusCode)';
    }
  }
}
