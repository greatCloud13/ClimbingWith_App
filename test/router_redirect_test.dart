import 'package:climbing_community_app/core/network/token_storage.dart';
import 'package:climbing_community_app/core/router/app_router.dart';
import 'package:climbing_community_app/features/auth/application/auth_controller.dart';
import 'package:climbing_community_app/features/auth/application/auth_providers.dart';
import 'package:climbing_community_app/features/auth/application/auth_state.dart';
import 'package:climbing_community_app/features/auth/data/auth_api.dart';
import 'package:climbing_community_app/features/auth/data/auth_repository.dart';
import 'package:climbing_community_app/features/auth/domain/current_user.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 실제 AuthController를 그대로 쓰되 login()만 네트워크 없이 상태를 바로
/// 바꾸도록 오버라이드 — 나머지(생성자에서 도는 _restore() 등)는 실제 코드와
/// 동일하게 동작시켜 라우터 리다이렉트 배선을 최대한 그대로 검증한다.
class _TestAuthController extends AuthController {
  _TestAuthController(super.repository);

  void loginAs(CurrentUser user) => state = AuthAuthenticated(user);

  void forceUnauthenticated() => state = const AuthUnauthenticated();
}

void main() {
  // 회귀 테스트 — /login 화면(셸 밖) → 로그인 성공 → /home(셸 안) 리다이렉트를
  // 빠르게 연달아 수행하면 StatefulShellRoute의 내부 GlobalKey가
  // "Multiple widgets used the same GlobalKey" 예외로 충돌했었다. 원인은
  // 셸을 나가는 페이지 전환 애니메이션이 끝나기 전에 셸이 다시 마운트되는
  // 타이밍 문제 — /login·/signup·/splash에 NoTransitionPage를 적용해
  // 전환 애니메이션 자체를 없애 해결함([app_router.dart] 참고).
  testWidgets('로그인 성공 시 /login에서 /home으로 즉시 리다이렉트된다', (tester) async {
    final repository = AuthRepository(
      api: AuthApi(Dio()),
      tokenStorage: TokenStorage(),
    );
    final controller = _TestAuthController(repository);

    final container = ProviderContainer(
      overrides: [authControllerProvider.overrideWith((ref) => controller)],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    // 생성자에서 시작된 _restore()는 테스트 환경에 시크릿 스토리지 플러그인
    // 채널이 없어 영영 안 끝날 수 있어(실기기/웹에서는 정상 종료됨) 직접 정착시킨다.
    await tester.pump();
    controller.forceUnauthenticated();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    router.go('/login');
    // 일부러 최소한의 프레임만 흘려보낸다 — 실사용자가 로그인 폼을 빠르게
    // 제출하는 상황(문제가 재현되던 조건)을 흉내낸다.
    await tester.pump();
    await tester.pump();
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/login',
    );

    controller.loginAs(
      const CurrentUser(username: 'a', nickname: 'a', role: 'USER'),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      tester.takeException(),
      isNull,
      reason: '셸(StatefulShellRoute) 재마운트 중 GlobalKey 충돌이 없어야 한다',
    );
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/home',
    );
  });
}
