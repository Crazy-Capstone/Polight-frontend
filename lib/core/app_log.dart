import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// 앱 전역 로그.
///
/// 웹에서는 `dart:developer`의 `log()`가 브라우저 콘솔에 나타나지 않으므로
/// print 계열(`debugPrint`)로 내보내고, 모바일에서는 태그별 필터가 되는
/// `developer.log`를 그대로 쓴다.
void appLog(String tag, String message) {
  if (kIsWeb) {
    debugPrint('[$tag] $message');
  } else {
    developer.log(message, name: tag);
  }
}
