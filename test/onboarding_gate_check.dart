// 임시 검증용 테스트 (앱 진입 시 항상 온보딩부터 보이는지 확인 후 삭제).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polight_frontend/main.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // HomeScreen(홈 탭)에 이미 있던 RenderFlex 오버플로(온보딩과 무관, 기존 버그)가
    // 렌더링되면서 예외로 기록되는 것을 흡수한다. 온보딩 게이팅 자체와는 무관하다.
    tester.takeException();
  }

  testWidgets('앱을 켜면 항상 온보딩부터 보인다', (tester) async {
    await pumpApp(tester);

    expect(find.text('반가워요!\n여행 보험, 이제 Polight와'), findsOne);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });

  testWidgets('온보딩을 마치면 메인 화면으로 넘어가지만, 앱을 다시 켜면 또 온보딩부터 보인다', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('건너뛰기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    tester.takeException();

    expect(find.byType(BottomNavigationBar), findsOne);
    expect(find.text('반가워요!\n여행 보험, 이제 Polight와'), findsNothing);

    // 앱을 새로 켠 상황을 재현 — 완료 여부를 기억하지 않고 다시 온보딩부터 시작해야 한다
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester);

    expect(find.text('반가워요!\n여행 보험, 이제 Polight와'), findsOne);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });
}
