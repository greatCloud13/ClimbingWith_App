import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

/// 로그인/로그아웃/세션 복원을 담당. 로그인·회원가입 폼 자체의 진행중/에러
/// 상태는 각 화면에서 지역적으로 들고, 이 컨트롤러는 "현재 로그인된 사용자가
/// 누구인가"라는 앱 전역 상태만 책임진다.
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthChecking()) {
    _restore();
  }

  final AuthRepository _repository;

  Future<void> _restore() async {
    try {
      final user = await _repository.restoreSession();
      state = user == null
          ? const AuthUnauthenticated()
          : AuthAuthenticated(user);
    } catch (_) {
      // 저장소를 읽지 못하면(플랫폼 채널 미지원 환경, 손상된 데이터 등) 로그아웃 상태로 취급한다.
      state = const AuthUnauthenticated();
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final user = await _repository.login(
      LoginRequest(username: username, password: password),
    );
    state = AuthAuthenticated(user);
  }

  Future<String> signUp({
    required String username,
    required String nickname,
    required String email,
    required String password,
  }) {
    return _repository.signUp(
      SignUpRequest(
        username: username,
        nickname: nickname,
        email: email,
        password: password,
      ),
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthUnauthenticated();
  }

  /// DioClient의 401 인터셉터에서 호출 — 서버가 토큰을 거부하면 강제 로그아웃.
  void forceLogout() {
    state = const AuthUnauthenticated();
  }
}
