// 임시 검증용 테스트 (뒤로가기 · 연도 필터 확인 후 삭제).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polight_frontend/screens/insurance_history_screen.dart';

void main() {
  // 카드 6장이 모두 들어가도록 세로로 긴 화면을 쓴다.
  Future<void> pumpPushedScreen(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 1400);
    addTearDown(tester.view.reset);

    // 실제 흐름대로 마이페이지 위에 push 된 상태를 만든다.
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InsuranceHistoryScreen(),
                  ),
                ),
                child: const Text('이전 보험 내역 보기'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('이전 보험 내역 보기'));
    await tester.pumpAndSettle();
  }

  testWidgets('뒤로가기 버튼을 누르면 이전 화면으로 돌아간다', (tester) async {
    await pumpPushedScreen(tester);
    expect(find.text('이전 보험 내역'), findsOne);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    // 화면이 pop 되어 진입 버튼만 남아야 한다.
    expect(find.text('이전 보험 내역'), findsNothing);
    expect(find.text('이전 보험 내역 보기'), findsOne);
  });

  testWidgets('연도 필터가 목록과 건수를 바꾼다', (tester) async {
    await pumpPushedScreen(tester);

    // 기본 '전체'
    expect(find.text('총 6건'), findsOne);
    expect(find.text('일본 여행'), findsOne);
    expect(find.text('파리 출장'), findsOne);

    // 2025 → 2건
    await tester.tap(find.text('2025'));
    await tester.pumpAndSettle();
    expect(find.text('총 2건'), findsOne);
    expect(find.text('일본 여행'), findsOne);
    expect(find.text('파리 출장'), findsNothing);

    // 2024 → 4건
    await tester.tap(find.text('2024'));
    await tester.pumpAndSettle();
    expect(find.text('총 4건'), findsOne);
    expect(find.text('일본 여행'), findsNothing);
    expect(find.text('파리 출장'), findsOne);

    // 2023 → 기록 없음
    await tester.tap(find.text('2023'));
    await tester.pumpAndSettle();
    expect(find.text('총 0건'), findsOne);
    expect(find.text('2023년 보험 기록이 없습니다'), findsOne);
  });
}
