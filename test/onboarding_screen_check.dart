// 임시 검증용 테스트 (온보딩 5슬라이드 확인 후 삭제).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polight_frontend/screens/onboarding_screen.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester, {VoidCallback? onFinished}) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: OnboardingScreen(onFinished: onFinished)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> swipeNext(WidgetTester tester) async {
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('5개 슬라이드를 넘기는 동안 오버플로 없이 문구가 모두 보인다', (tester) async {
    await pumpScreen(tester);

    expect(find.text('반가워요!\n여행 보험, 이제 Polight와'), findsOne);
    expect(find.text('건너뛰기'), findsOne);

    await swipeNext(tester);
    expect(find.text('내 보장 내역을\n한눈에 확인하세요'), findsOne);

    await swipeNext(tester);
    expect(find.text('궁금한 건 PoPo에게\n바로 물어보세요'), findsOne);

    await swipeNext(tester);
    expect(find.text('아플 때 가까운 병원,\n경찰서까지 바로 연결'), findsOne);

    await swipeNext(tester);
    expect(find.text('3초 만에 시작해요\n가입은 카카오로 간단하게'), findsOne);
    // 마지막 페이지에는 건너뛰기가 없고 카카오 버튼이 있다
    expect(find.text('건너뛰기'), findsNothing);
    expect(find.text('카카오로 시작하기'), findsOne);

    expect(tester.takeException(), isNull);
  });

  testWidgets('다음 버튼을 4번 누르면 마지막 페이지에 도달한다', (tester) async {
    await pumpScreen(tester);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
    }

    expect(find.text('카카오로 시작하기'), findsOne);
  });

  testWidgets('건너뛰기를 누르면 onFinished가 호출된다', (tester) async {
    var finished = false;
    await pumpScreen(tester, onFinished: () => finished = true);

    await tester.tap(find.text('건너뛰기'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
  });

  testWidgets(
    '카카오 버튼을 누르면 로그인 화면으로 이동한다 (.env 미설정 시 안내 문구, 크래시 없음)',
    (tester) async {
      var finished = false;
      await pumpScreen(tester, onFinished: () => finished = true);

      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('다음'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('카카오로 시작하기'));
      await tester.pumpAndSettle();

      // 로그인이 실제로 끝난 게 아니므로 아직 온보딩을 벗어나면 안 된다
      expect(finished, isFalse);
      // 테스트 환경에는 .env가 로드되지 않으므로 설정 안내 화면이 보여야 한다
      // (webview_flutter는 플랫폼 채널이 없어 실제로 띄울 수 없음 — 여기서 막히는 게 정상)
      expect(find.text('카카오 로그인'), findsOne);
      expect(tester.takeException(), isNull);

      // 닫기를 누르면 아무 부작용 없이 온보딩으로 돌아온다
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(finished, isFalse);
      expect(find.text('카카오로 시작하기'), findsOne);
    },
  );
}
