// 임시 검증용 테스트 (날짜 선택 규칙 확인 후 삭제).
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polight_frontend/screens/trip_info_screen.dart';

void main() {
  // 기본 테스트 화면(800x600)에서는 달력이 화면 밖이라 탭이 빗나간다.
  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(420, 1400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: TripInfoScreen(file: PlatformFile(name: 'test.pdf', size: 0)),
    ));
    await tester.pumpAndSettle();
  }

  // 스텝 인디케이터의 1·2·3과 겹치지 않도록 달력 셀 안에서만 날짜를 찾는다.
  Finder dayCell(int day) => find.widgetWithText(InkResponse, '$day');

  /// [focused] 달에서 [target] 달까지 넘긴 뒤 해당 날짜를 탭하고, 보고 있는 달을 돌려준다.
  Future<DateTime> selectDate(
    WidgetTester tester,
    DateTime focused,
    DateTime target,
  ) async {
    var current = focused;
    final targetMonth = DateTime(target.year, target.month);
    while (current.isBefore(targetMonth)) {
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      current = DateTime(current.year, current.month + 1);
    }
    await tester.tap(dayCell(target.day));
    await tester.pumpAndSettle();
    return current;
  }

  final now = DateTime.now();
  final thisMonth = DateTime(now.year, now.month);

  testWidgets('날짜 탭: 출발일 → 도착일 → 취소', (tester) async {
    await pumpScreen(tester);

    final a = now.add(const Duration(days: 1));
    final b = now.add(const Duration(days: 3));

    // 시작은 아무것도 선택되지 않은 상태
    expect(find.text('날짜를 선택해 주세요'), findsOneWidget);
    expect(find.text('선택해 주세요'), findsNWidgets(2));

    // 1) 첫 탭 → 출발일
    var focused = await selectDate(tester, thisMonth, a);
    expect(find.text('선택해 주세요'), findsOneWidget, reason: '도착일만 비어 있어야 함');

    // 2) 다른 날짜 탭 → 도착일 자동 지정
    focused = await selectDate(tester, focused, b);
    expect(find.text('2박 3일'), findsOneWidget);
    expect(find.text('선택해 주세요'), findsNothing);

    // 3) 한 번 더 탭 → 취소
    await selectDate(tester, focused, b);
    expect(find.text('날짜를 선택해 주세요'), findsOneWidget);
    expect(find.text('선택해 주세요'), findsNWidgets(2));
  });

  testWidgets('출발일보다 앞 날짜를 고르면 순서가 자동 정렬된다', (tester) async {
    await pumpScreen(tester);

    final later = now.add(const Duration(days: 5));
    final earlier = now.add(const Duration(days: 2));

    var focused = await selectDate(tester, thisMonth, later);
    // 뒤 날짜를 먼저 골랐어도 앞 날짜가 출발일이 되어야 한다.
    focused = await selectDate(tester, focused, earlier);

    expect(find.text('3박 4일'), findsOneWidget);
  });

  testWidgets('90일을 넘기면 안내가 뜨고 다음으로 넘어갈 수 없다', (tester) async {
    await pumpScreen(tester);

    final start = now.add(const Duration(days: 1));
    final end = start.add(const Duration(days: 120));

    var focused = await selectDate(tester, thisMonth, start);
    await selectDate(tester, focused, end);

    expect(find.text('90일이 넘는 일정이에요'), findsOneWidget);
    expect(find.text('날짜 다시 선택'), findsOneWidget);

    final next = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(next.onPressed, isNull, reason: '다음 버튼이 잠겨 있어야 함');

    // 안내의 버튼으로 한 번에 초기화
    await tester.tap(find.text('날짜 다시 선택'));
    await tester.pumpAndSettle();
    expect(find.text('날짜를 선택해 주세요'), findsOneWidget);
    expect(find.text('90일이 넘는 일정이에요'), findsNothing);
  });

  testWidgets('정확히 90일이면 안내가 뜨지 않는다', (tester) async {
    await pumpScreen(tester);

    final start = now.add(const Duration(days: 1));
    final end = start.add(const Duration(days: 89)); // 출발일 포함 총 90일

    var focused = await selectDate(tester, thisMonth, start);
    await selectDate(tester, focused, end);

    expect(find.text('90일이 넘는 일정이에요'), findsNothing);
    expect(find.text('89박 90일'), findsOneWidget);
  });

  testWidgets('91일이면 안내가 뜬다', (tester) async {
    await pumpScreen(tester);

    final start = now.add(const Duration(days: 1));
    final end = start.add(const Duration(days: 90)); // 총 91일

    var focused = await selectDate(tester, thisMonth, start);
    await selectDate(tester, focused, end);

    expect(find.text('90일이 넘는 일정이에요'), findsOneWidget);
    expect(find.text('91일 · 90일 초과'), findsOneWidget);
  });
}
