import 'models/coverage_result.dart';

/// 보장 항목(Coverage)을 화면에 보여줄 이모지/금액 문구로 바꾸는 공용 로직.
/// coverage_screen과 home_screen이 같은 규칙을 쓰도록 여기서만 관리한다.

String emojiForCoverage(Coverage coverage) {
  final text = '${coverage.category ?? ''} ${coverage.title}';
  if (text.contains('치과')) return '🦷';
  if (text.contains('의료') || text.contains('질병') || text.contains('상해')) {
    return '🏥';
  }
  if (text.contains('항공') || text.contains('지연') || text.contains('결항')) {
    return '✈️';
  }
  if (text.contains('수하물') ||
      text.contains('휴대품') ||
      text.contains('도난') ||
      text.contains('분실')) {
    return '🧳';
  }
  if (text.contains('이송') || text.contains('구급')) return '🚑';
  if (text.contains('배상')) return '⚖️';
  if (text.contains('여권')) return '🛂';
  if (text.contains('중단') || text.contains('취소')) return '🚨';
  return '🛡️';
}

String limitLabelFor(Coverage coverage) {
  final label = coverage.limitLabel;
  if (label != null && label.isNotEmpty) return label;

  final amount = coverage.limitAmount;
  if (amount == null) return '한도 확인 필요';

  final currency = coverage.limitCurrency;
  final isWon =
      currency == null || currency.isEmpty || currency == '원' || currency == 'KRW';
  if (!isWon) return '최대 ${withComma(amount.toInt())}$currency';
  return '최대 ${formatKoreanWon(amount)}';
}

/// 원 단위 숫자를 만/억 단위 한국식 표기로 바꾼다. 예) 100000000 → "1억", 5000000 → "500만".
String formatKoreanWon(num amount) {
  final value = amount.toInt();
  if (value >= 100000000) {
    final eok = value ~/ 100000000;
    final man = (value % 100000000) ~/ 10000;
    return man == 0 ? '$eok억원' : '$eok억 $man만원';
  }
  if (value >= 10000) {
    final man = value ~/ 10000;
    final rest = value % 10000;
    return rest == 0 ? '$man만원' : '$man만 ${withComma(rest)}원';
  }
  return '${withComma(value)}원';
}

String withComma(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
