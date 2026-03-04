import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/main_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const LottoApp());
}

class LottoApp extends StatelessWidget {
  const LottoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lotto 번호 통계 분석',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF5A623),
          brightness: Brightness.dark,
        ),
        fontFamily: 'NotoSansKR',
      ),
      home: const MainPage(),
    );
  }
}
