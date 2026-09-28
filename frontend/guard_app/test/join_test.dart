import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guard_app/app.dart';
import 'package:guard_app/core/authed_http.dart';
import 'package:guard_app/features/join/join_screen.dart';

/// The join form is a scrolling list; make it tall enough to build every field.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('login screen links to the join screen', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const GuardApp(isAuthenticated: false));

    await tester.tap(find.text('New here? Join with a unit code'));
    await tester.pumpAndSettle();

    expect(find.byType(JoinScreen), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Create account'), findsOne);
  });

  testWidgets('a /join?code= link pre-fills the unit code', (tester) async {
    await tester.pumpWidget(const GuardApp(isAuthenticated: false));

    navigatorKey.currentState!.pushNamed('/join?code=K7QM-4XPA');
    await tester.pumpAndSettle();

    expect(find.byType(JoinScreen), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'K7QM-4XPA'), findsOneWidget);
  });

  testWidgets('sign-up form validates before submitting', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(
      const MaterialApp(home: JoinScreen(initialCode: 'K7QM-4XPA')),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'longenough1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'different1',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'bad');

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(find.text('Enter a valid email'), findsOneWidget);
    // Rank, first name, last name
    expect(find.text('Required'), findsNWidgets(3));
  });
}
