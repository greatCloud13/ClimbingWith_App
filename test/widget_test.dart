import 'package:flutter_test/flutter_test.dart';

import 'package:climbing_community_app/main.dart';

void main() {
  testWidgets('앱이 피드 탭과 함께 정상적으로 렌더링된다', (WidgetTester tester) async {
    await tester.pumpWidget(const ClimbingCommunityApp());
    await tester.pumpAndSettle();

    expect(find.text('클라임로그'), findsOneWidget);
    expect(find.text('피드'), findsOneWidget);
    expect(find.text('클라이밍장'), findsOneWidget);
    expect(find.text('기록'), findsOneWidget);
  });
}
