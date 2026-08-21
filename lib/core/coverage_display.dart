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
  // 백엔드가 "1000000" 처럼 raw 숫자로 주는 경우가 있어 그대로 쓰지 않고 다듬는다.
  if (label != null && label.isNotEmpty) return humanizeMoneyText(label);

  final amount = coverage.limitAmount;
  if (amount == null) return '한도 확인 필요';

  final currency = coverage.limitCurrency;
  final isWon = currency == null ||
      currency.isEmpty ||
      currency == '원' ||
      currency == 'KRW' ||
      currency == '₩';
  if (!isWon) return '최대 ${withComma(amount.toInt())}$currency';
  return '최대 ${formatKoreanWon(amount)}';
}

/// 금액 앞에 붙는 통화 표시(₩, KRW, W). 우리는 '원'을 뒤에 붙이므로 떼어낸다.
/// 바로 뒤에 숫자가 오는 경우에만 떼서, 통화 코드만 있는 문구는 건드리지 않는다.
final RegExp _leadingCurrency = RegExp(r'(?:₩|KRW|\bW)\s*(?=\d)');

/// 백엔드가 준 금액 문구를 만/억 단위로 다듬는다.
///
/// - `"1000000"`, `"1,000,000원"` → `"100만원"`
/// - `"₩1000000"`, `"KRW 1000000"` → `"100만원"` (앞에 붙은 통화 표시는 뗀다)
/// - `"최대 100000000원"` → `"최대 1억원"`
/// - `"한도 없음"`, `"3시간 이상"`처럼 금액이 아니거나 이미 만/억으로 쓰인 문구는 그대로 둔다.
String humanizeMoneyText(String raw) {
  // 숫자 앞에 붙은 통화 표시는 '원' 접미사와 중복되므로 먼저 제거한다.
  final text = raw.replaceAll(_leadingCurrency, '').trim();
  if (text.isEmpty) return text;

  // 문자열 전체가 금액 하나인 경우 (원 단위까지 붙여서 반환)
  final whole = RegExp(r'^([\d,]+)\s*원?$').firstMatch(text);
  if (whole != null) {
    final value = int.tryParse(whole.group(1)!.replaceAll(',', ''));
    if (value != null) return formatKoreanWon(value);
  }

  // 문장 속에 큰 숫자가 섞여 있는 경우. 숫자 부분만 만/억으로 바꾸고,
  // 뒤에 '원'이 이미 붙어 있지 않으면 붙여 준다.
  return text.replaceAllMapped(RegExp(r'\d[\d,]*'), (m) {
    final digits = m[0]!.replaceAll(',', '');
    final value = int.tryParse(digits);
    if (value == null || value < 10000) return m[0]!;

    final rest = text.substring(m.end).trimLeft();
    final alreadyHasWon = rest.startsWith('원');
    return alreadyHasWon ? _koreanUnits(value) : '${_koreanUnits(value)}원';
  });
}

/// 만/억 단위 표기에서 '원'을 뺀 형태. 예) 100000000 → "1억", 5000000 → "500만".
String _koreanUnits(int value) {
  if (value >= 100000000) {
    final eok = value ~/ 100000000;
    final man = (value % 100000000) ~/ 10000;
    return man == 0 ? '$eok억' : '$eok억 $man만';
  }
  if (value >= 10000) {
    final man = value ~/ 10000;
    final rest = value % 10000;
    return rest == 0 ? '$man만' : '$man만 ${withComma(rest)}';
  }
  return withComma(value);
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
