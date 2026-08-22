import 'package:flutter/widgets.dart';

/// 챗봇 답변이 `**강조**` 형태의 마크다운으로 오기 때문에, 그 부분만 굵게 그린다.
///
/// 전체 마크다운을 지원하는 패키지를 붙일 만한 상황은 아니라서 굵게(`**` / `__`)만
/// 처리하고, 나머지 문자는 원문 그대로 둔다. 짝이 맞지 않는 `**` 는 기호를 그대로
/// 보여준다(문구가 잘리는 것보다 낫다).
List<TextSpan> parseBoldSpans(String text, {TextStyle? boldStyle}) {
  final marker = RegExp(r'(\*\*|__)(.+?)\1', dotAll: true);
  final spans = <TextSpan>[];
  var index = 0;

  for (final match in marker.allMatches(text)) {
    if (match.start > index) {
      spans.add(TextSpan(text: text.substring(index, match.start)));
    }
    spans.add(
      TextSpan(
        text: match.group(2),
        style: boldStyle ?? const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
    index = match.end;
  }

  if (index < text.length) {
    spans.add(TextSpan(text: text.substring(index)));
  }
  return spans;
}

/// `**강조**` 를 굵게 반영해서 그리는 Text.
class InlineMarkdownText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const InlineMarkdownText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: style,
        children: parseBoldSpans(
          text,
          boldStyle: style.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
