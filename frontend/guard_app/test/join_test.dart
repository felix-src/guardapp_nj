import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guard_app/app.dart';
import 'package:guard_app/core/authed_http.dart';
import 'package:guard_app/features/join/join_screen.dart';
import 'package:guard_app/features/org/org_api.dart';
import 'package:guard_app/features/org/org_models.dart';

/// The join form is a scrolling list; make it tall enough to build every field.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

// Same shape as GET /auth/join/:code
final sampleJoinInfo = JoinInfo.fromJson(
  jsonDecode('''
{"unitName":"HHC, 1st Battalion","structure":[
  {"id":1,"name":"Company HQ","kind":"company_hq","children":[],"roles":[
    {"key":"commander","label":"Commander"},
    {"key":"first_sergeant","label":"First Sergeant"}]},
  {"id":2,"name":"1st Platoon","kind":"platoon","roles":[],"children":[
    {"id":3,"name":"Platoon HQ","kind":"platoon_hq","children":[],"roles":[
      {"key":"platoon_leader","label":"Platoon Leader"}]},
    {"id":4,"name":"2nd Squad","kind":"rifle_squad","children":[],"roles":[
      {"key":"squad_leader","label":"Squad Leader"},
      {"key":"rifleman","label":"Rifleman"}]}]}
]}'''),
);

Future<JoinInfo> fakeLookup(String code) async {
  if (code.toUpperCase() == 'K7QM-4XPA') return sampleJoinInfo;
  throw JoinCodeException('Invalid or expired unit code.');
}

Future<void> pumpJoin(WidgetTester tester, {String? code}) async {
  useTallScreen(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: JoinScreen(initialCode: code, lookupJoinCode: fakeLookup),
    ),
  );
  await tester.pumpAndSettle();
}

/// Opens the dropdown labelled [label] and returns once its menu is open.
Future<void> openDropdown(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> pick(WidgetTester tester, String label, String option) async {
  await openDropdown(tester, label);
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('login screen links to the join screen', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const GuardApp(isAuthenticated: false));

    await tester.tap(find.text('New here? Join with a unit code'));
    await tester.pumpAndSettle();

    expect(find.byType(JoinScreen), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Unit code'), findsOneWidget);
  });

  testWidgets('a /join?code= link passes the code to the join screen', (
    tester,
  ) async {
    await tester.pumpWidget(const GuardApp(isAuthenticated: false));

    navigatorKey.currentState!.pushNamed('/join?code=K7QM-4XPA');
    await tester.pumpAndSettle();

    final screen = tester.widget<JoinScreen>(find.byType(JoinScreen));
    expect(screen.initialCode, 'K7QM-4XPA');
  });

  testWidgets('a valid code shows the unit and position fields', (
    tester,
  ) async {
    await pumpJoin(tester, code: 'k7qm-4xpa');

    expect(find.text('HHC, 1st Battalion'), findsOneWidget);
    expect(find.text('Platoon / section'), findsOneWidget);
    // No squad or role choice until a platoon is picked
    expect(find.text('Squad / HQ'), findsNothing);
    expect(find.text('Duty role'), findsNothing);
  });

  testWidgets('an invalid code stays on the code step with the error', (
    tester,
  ) async {
    await pumpJoin(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Unit code'),
      'AAAA-AAAA',
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid or expired unit code.'), findsOneWidget);
    expect(find.text('Platoon / section'), findsNothing);
  });

  testWidgets('platoon narrows squads, squad narrows roles', (tester) async {
    await pumpJoin(tester, code: 'K7QM-4XPA');

    await pick(tester, 'Platoon / section', '1st Platoon');
    expect(find.text('Squad / HQ'), findsOneWidget);

    await pick(tester, 'Squad / HQ', '2nd Squad');
    await openDropdown(tester, 'Duty role');
    expect(find.text('Rifleman'), findsWidgets);
    expect(find.text('Commander'), findsNothing);
    await tester.tap(find.text('Rifleman').last);
    await tester.pumpAndSettle();

    // Company HQ has no squads; its own roles apply
    await pick(tester, 'Platoon / section', 'Company HQ');
    expect(find.text('Squad / HQ'), findsNothing);
    await openDropdown(tester, 'Duty role');
    expect(find.text('Commander'), findsWidgets);
    expect(find.text('Rifleman'), findsNothing);
  });

  testWidgets('sign-up form validates before submitting', (tester) async {
    await pumpJoin(tester, code: 'K7QM-4XPA');

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
    // Platoon, rank, first name, last name
    expect(find.text('Required'), findsNWidgets(4));
  });
}
