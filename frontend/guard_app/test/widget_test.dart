import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guard_app/app.dart';

void main() {
  testWidgets('unauthenticated app starts on the login screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GuardApp(isAuthenticated: false));

    expect(find.widgetWithText(AppBar, 'Login'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });
}
