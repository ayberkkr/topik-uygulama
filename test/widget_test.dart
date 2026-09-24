import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_mobile/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home screen loads swipeable activities', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const TopikApp());
    await tester.pump();
    expect(find.text('한국어 퀴즈'), findsOneWidget);
    expect(find.text('Günlük Sınav'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
