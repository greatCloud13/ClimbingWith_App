import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/domain/current_user.dart';

/// AccessToken과 로그인 사용자 정보를 기기 보안 저장소(Keychain/Keystore)에 보관한다.
/// SharedPreferences는 평문 저장이라 토큰 같은 민감정보에는 쓰지 않는다.
///
/// 현재 백엔드에 세션 복원용 "내 정보 조회" API가 없어, 로그인 응답에
/// 담긴 사용자 정보를 토큰과 함께 저장해두고 앱 재시작 시 그대로 복원한다.
/// 저장된 토큰이 만료됐다면 이후 첫 인증 필요 API 호출에서 401을 받아
/// 로그아웃 처리된다. `/api/auth/me` 같은 엔드포인트가 생기면 이 복원
/// 로직을 그 API 호출로 교체하는 것이 더 안전하다 (역할 변경 등이 반영됨).
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'access_token';
  static const _userKey = 'current_user';

  final FlutterSecureStorage _storage;

  Future<void> saveSession(String token, CurrentUser user) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<CurrentUser?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    return CurrentUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}
