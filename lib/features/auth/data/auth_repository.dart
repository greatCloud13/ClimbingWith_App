import '../../../core/network/token_storage.dart';
import '../domain/current_user.dart';
import 'auth_api.dart';
import 'auth_models.dart';

class AuthRepository {
  AuthRepository({required AuthApi api, required TokenStorage tokenStorage})
    : _api = api,
      _tokenStorage = tokenStorage;

  final AuthApi _api;
  final TokenStorage _tokenStorage;

  Future<String> signUp(SignUpRequest request) => _api.signUp(request);

  Future<CurrentUser> login(LoginRequest request) async {
    final response = await _api.login(request);
    final user = CurrentUser(
      username: response.username,
      nickname: response.nickname,
      role: response.role,
      managedGymId: response.managedGymId,
    );
    try {
      await _tokenStorage.saveSession(response.token, user);
    } catch (_) {
      // 세션 저장(보안 저장소 쓰기)이 실패해도 로그인 자체는 성공한 것으로
      // 처리한다 — 그래야 인증 화면에서 홈으로 넘어간다. 저장 실패 시
      // 다음 앱 실행 때 재로그인이 필요할 수 있지만, 지금 이 세션까지
      // 막을 이유는 없다.
    }
    return user;
  }

  Future<void> logout() => _tokenStorage.clearSession();

  Future<CurrentUser?> restoreSession() async {
    final token = await _tokenStorage.readToken();
    if (token == null) return null;
    return _tokenStorage.readUser();
  }
}
