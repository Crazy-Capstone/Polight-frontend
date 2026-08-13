// 임시 프리뷰 진입점 (스크린샷 확인용). 확인 후 삭제됩니다.
import 'package:flutter/material.dart';
import 'screens/insurance_history_screen.dart';

void main() => runApp(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: InsuranceHistoryScreen(),
      ),
    );
