import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/application/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/feed/feed_screen.dart';
import '../../features/gym/gym_screen.dart';
import '../../features/record/record_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/shell/splash_screen.dart';

/// authControllerProvider가 바뀔 때마다 GoRouter의 redirect를 다시 평가시키는
/// 브릿지. GoRouter 인스턴스 자체는 재생성하지 않고(내비게이션 스택 보존),
/// refreshListenable을 통해 redirect 콜백만 재실행되게 한다.
class _AuthRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final Provider<_AuthRefreshNotifier> _authRefreshProvider = Provider<_AuthRefreshNotifier>((ref) {
  final notifier = _AuthRefreshNotifier();
  ref.listen(authControllerProvider, (_, _) => notifier.notify());
  return notifier;
});

final Provider<GoRouter> routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: ref.read(_authRefreshProvider),
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
      final atSplash = state.matchedLocation == '/splash';

      return switch (authState) {
        AuthChecking() => atSplash ? null : '/splash',
        AuthUnauthenticated() => loggingIn ? null : '/login',
        AuthAuthenticated() => (loggingIn || atSplash) ? '/feed' : null,
      };
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const SignUpScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/feed', builder: (_, _) => const FeedScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/gym', builder: (_, _) => const GymScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/record', builder: (_, _) => const RecordScreen())]),
        ],
      ),
    ],
  );
});
