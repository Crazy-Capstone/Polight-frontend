// 임시 검증용 테스트 (마이페이지 닉네임/프로필 사진 적용 확인 후 삭제).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polight_frontend/screens/mypage_screen.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: MypageScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets(
    '저장된 프로필이 없으면(보안 저장소 접근 불가 포함) 기본 문구로 안전하게 표시된다',
    (tester) async {
      await pumpScreen(tester);

      // 테스트 환경에는 flutter_secure_storage 플랫폼 채널이 없어 조회가 실패하는데,
      // 그 경우에도 크래시 없이 기본값("회원 님" + 🐰)으로 떨어져야 한다.
      expect(find.text('회원 님'), findsOne);
      expect(find.text('🐰'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
