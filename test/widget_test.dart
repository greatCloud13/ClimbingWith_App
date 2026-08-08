import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:climbing_community_app/core/network/token_storage.dart';
import 'package:climbing_community_app/features/auth/application/auth_providers.dart';
import 'package:climbing_community_app/features/auth/domain/current_user.dart';
import 'package:climbing_community_app/main.dart';

/// 위젯 테스트는 실제 기기 보안 저장소(플랫폼 채널)에 접근할 수 없으므로
/// 세션이 없는 상태를 즉시 반환하는 가짜 저장소로 교체한다.
class _FakeTokenStorage implements TokenStorage {
  @override
  Future<void> saveSession(String token, CurrentUser user) async {}

  @override
  Future<String?> readToken() async => null;

  @override
  Future<CurrentUser?> readUser() async => null;

  @override
  Future<void> clearSession() async {}
}

void main() {
  testWidgets('로그인 전에도 홈 화면이 게스트로 보인다', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStorageProvider.overrideWithValue(_FakeTokenStorage())],
        child: const ClimbingCommunityApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('오늘은 어느 암장으로\n가실건가요?'), findsOneWidget);
    expect(find.text('로그인하기'), findsOneWidget);
  });
}
