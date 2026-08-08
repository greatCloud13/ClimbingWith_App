import '../domain/current_user.dart';

sealed class AuthState {
  const AuthState();
}

/// 앱 시작 시 저장된 세션을 복원하는 중.
class AuthChecking extends AuthState {
  const AuthChecking();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final CurrentUser user;
}
