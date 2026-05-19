import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/pages/login.dart';

void main() {
  testWidgets('Login page renders required fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(),
      ),
    );

    expect(find.text('SahaTakip'), findsOneWidget);
    expect(find.text('Kullanıcı Adı'), findsOneWidget);
    expect(find.text('Şifre'), findsOneWidget);
    expect(find.text('Giriş Yap'), findsWidgets);
  });
}
