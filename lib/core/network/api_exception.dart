import 'package:dio/dio.dart';

/// 서버 에러 응답을 사용자에게 보여줄 메시지로 정규화한다.
///
/// 백엔드의 유효성 검증 실패 응답 포맷이 아직 확정되지 않아(Spring 기본
/// 예외 핸들러 그대로일 수도, 커스텀 포맷일 수도 있음) 알려진 몇 가지
/// 형태(`message`, `errors[].defaultMessage`, `error`)를 순서대로 시도하고
/// 모두 실패하면 상태코드 기반 기본 메시지로 대체한다. 실제 포맷이
/// 확정되면 이 파서만 갱신하면 된다.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'] as String? ??
          data['error'] as String? ??
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
