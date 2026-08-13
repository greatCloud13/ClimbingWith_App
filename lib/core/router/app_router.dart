import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/application/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/gym/domain/gym_detail.dart';
import '../../features/gym/domain/sector.dart';
import '../../features/gym/gym_screen.dart';
import '../../features/gym/presentation/gym_board_screen.dart';
import '../../features/gym/presentation/gym_detail_screen.dart';
import '../../features/gym/presentation/sector_problems_screen.dart';
import '../../features/gym_manage/presentation/gym_manager_board_screen.dart';
import '../../features/gym_manage/presentation/gym_post_form_screen.dart';
import '../theme/app_colors.dart';
import '../../features/home/domain/notice.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/notice_detail_screen.dart';
import '../../features/more/more_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/shell/record_or_manage_screen.dart';
import '../../features/shell/splash_screen.dart';

/// authControllerProvider가 바뀔 때마다 GoRouter의 redirect를 다시 평가시키는
/// 브릿지. GoRouter 인스턴스 자체는 재생성하지 않고(내비게이션 스택 보존),
/// refreshListenable을 통해 redirect 콜백만 재실행되게 한다.
class _AuthRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final Provider<_AuthRefreshNotifier> _authRefreshProvider =
    Provider<_AuthRefreshNotifier>((ref) {
      final notifier = _AuthRefreshNotifier();
      ref.listen(authControllerProvider, (_, _) => notifier.notify());
      return notifier;
    });

/// 로그인 없이는 볼 수 없는 경로. 그 외(홈/암장/더보기/공지 등)는 게스트도 접근 가능 —
/// 홈 화면 안에서 개인화 섹션(즐겨찾기/스트릭/친구활동)만 로그인을 유도한다.
const _authRequiredPaths = {
  '/profile',
  '/record',
  '/gym-manage/board',
  '/gym-manage/board/write',
};

final Provider<GoRouter> routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: ref.read(_authRefreshProvider),
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final loggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      final atSplash = state.matchedLocation == '/splash';
      final requiresAuth = _authRequiredPaths.contains(state.matchedLocation);

      return switch (authState) {
        AuthChecking() => atSplash ? null : '/splash',
        AuthUnauthenticated() =>
          requiresAuth ? '/login' : (atSplash ? '/home' : null),
        AuthAuthenticated() => (loggingIn || atSplash) ? '/home' : null,
      };
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (_, state) =>
            NoTransitionPage(key: state.pageKey, child: const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (_, state) =>
            NoTransitionPage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (_, state) =>
            NoTransitionPage(key: state.pageKey, child: const SignUpScreen()),
      ),
      GoRoute(
        path: '/notice/:id',
        builder: (context, state) => NoticeDetailScreen(
          noticeId: state.pathParameters['id']!,
          notice: state.extra as Notice?,
        ),
      ),
      GoRoute(
        path: '/gym/:id',
        builder: (context, state) =>
            GymDetailScreen(gymId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/gym/:id/board',
        builder: (context, state) => GymBoardScreen(
          gymId: int.parse(state.pathParameters['id']!),
          accent: (state.extra as Color?) ?? AppColors.holdLime,
        ),
      ),
      GoRoute(
        path: '/gym-manage/board',
        builder: (_, _) => const GymManagerBoardScreen(),
      ),
      GoRoute(
        path: '/gym-manage/board/write',
        builder: (context, state) =>
            GymPostFormScreen(postId: state.extra as int?),
      ),
      GoRoute(
        path: '/gym/:id/sector/:sectorId',
        builder: (context, state) {
          final extra = state.extra as Map<String, Object?>?;
          return SectorProblemsScreen(
            gymId: state.pathParameters['id']!,
            sectorId: state.pathParameters['sectorId']!,
            gym: extra?['gym'] as GymDetail?,
            sector: extra?['sector'] as Sector?,
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/gym', builder: (_, _) => const GymScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/record',
                builder: (_, _) => const RecordOrManageScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/more', builder: (_, _) => const MoreScreen()),
            ],
          ),
        ],
      ),
    ],
  );
});
