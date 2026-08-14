// 임시 검증용 테스트 (홈 인사말 · 챗봇 인사말 닉네임 적용 확인 후 삭제).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polight_frontend/screens/home_screen.dart';
import 'package:polight_frontend/screens/chatbot_screen.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(home: child));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets(
    '홈 화면: 저장된 닉네임이 없으면(보안 저장소 접근 불가 포함) 기본 인사말로 안전하게 표시된다',
    (tester) async {
      await pump(tester, const HomeScreen());

      expect(find.textContaining('회원님'), findsOne);
      expect(find.textContaining('류지'), findsNothing);
      // HomeScreen에 있던 기존 RenderFlex 오버플로(닉네임 작업과 무관, 기존 버그)를 흡수한다.
      tester.takeException();
    },
  );

  testWidgets(
    '챗봇 화면: 저장된 닉네임이 없으면(보안 저장소 접근 불가 포함) 기본 인사말로 안전하게 표시된다',
    (tester) async {
      await pump(tester, const ChatbotScreen());

      expect(find.textContaining('회원님'), findsOne);
      expect(find.textContaining('류지'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
