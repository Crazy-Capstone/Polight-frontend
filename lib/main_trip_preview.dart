// 임시 프리뷰 진입점 (스크린샷 확인용). 확인 후 삭제됩니다.
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'screens/trip_info_screen.dart';

void main() => runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: TripInfoScreen(file: PlatformFile(name: 'preview.pdf', size: 0)),
      ),
    );
