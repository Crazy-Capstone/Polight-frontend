// 임시 검증용 테스트 (여행 선택 시트 확인 후 삭제).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polight_frontend/screens/coverage_screen.dart';
import 'package:polight_frontend/widgets/trip_select_sheet.dart';

void main() {
  Future<void> pumpCoverage(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: CoverageScreen()));
    await tester.pumpAndSettle();
  }

  // 시트 안의 항목만 겨냥한다(뱃지/배너의 '일본 여행'과 겹치지 않도록).
  Finder rowTitle(String name) => find.descendant(
        of: find.byType(TripSelectSheet),
        matching: find.text(name),
      );

  testWidgets('뱃지를 누르면 여행 선택 시트가 열린다', (tester) async {
    await pumpCoverage(tester);
    expect(find.byType(TripSelectSheet), findsNothing);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(TripSelectSheet), findsOne);
    expect(find.text('여행 선택'), findsOne);
    expect(find.text('다른 여행의 보장 내역으로 바꿔서 볼 수 있어요'), findsOne);
    expect(rowTitle('파리 출장'), findsOne);
  });

  testWidgets('여행을 고르고 확인하면 뱃지와 배너가 바뀐다', (tester) async {
    await pumpCoverage(tester);
    // 처음에는 진행 중인 일본 여행
    expect(find.text('일본 여행'), findsOne);
    expect(find.text('D-7 남음'), findsOne);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();

    await tester.tap(rowTitle('파리 출장'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이 여행으로 보기'));
    await tester.pumpAndSettle();

    // 시트가 닫히고 선택한 여행이 반영된다
    expect(find.byType(TripSelectSheet), findsNothing);
    expect(find.text('파리 출장'), findsOne);
    expect(find.text('2024.11.03 – 11.09'), findsOne);
    // 만료된 여행이므로 남은 일수 대신 상태를 보여준다
    expect(find.text('만료'), findsOne);
    expect(find.text('D-7 남음'), findsNothing);
  });

  testWidgets('닫기를 누르면 선택이 반영되지 않는다', (tester) async {
    await pumpCoverage(tester);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();
    await tester.tap(rowTitle('베트남 다낭 가족여행'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();

    expect(find.byType(TripSelectSheet), findsNothing);
    // 원래 여행이 그대로 남아 있어야 한다
    expect(find.text('일본 여행'), findsOne);
    expect(find.text('베트남 다낭 가족여행'), findsNothing);
  });
}
