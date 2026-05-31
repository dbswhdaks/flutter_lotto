import 'package:flutter_test/flutter_test.dart';

import 'package:lotto_app/main.dart';

void main() {
  testWidgets('App boots with main title', (WidgetTester tester) async {
    await tester.pumpWidget(const LottoApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Lotto 번호 통계 분석'), findsOneWidget);
  });
}
