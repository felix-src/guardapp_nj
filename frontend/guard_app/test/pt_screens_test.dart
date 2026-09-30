import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guard_app/features/pt/elapsed_clock.dart';
import 'package:guard_app/features/pt/event_timer_screen.dart';
import 'package:guard_app/features/pt/lap_session.dart';
import 'package:guard_app/features/pt/lap_tracker_screen.dart';
import 'package:guard_app/features/pt/pt_calculator_screen.dart';
import 'package:guard_app/features/pt/pt_hub_screen.dart';
import 'package:guard_app/features/pt/pt_standard.dart';
import 'package:guard_app/features/pt/standards.dart';

class FakeTime {
  DateTime value = DateTime(2026, 9, 29, 6);
  DateTime call() => value;
  void advance(Duration d) => value = value.add(d);
}

void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  late PtStandard aft;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    aft = await PtStandards.current(date: DateTime(2026, 9, 29));
  });

  String summary(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('pt-summary'))).data!;

  Future<void> enter(WidgetTester tester, String eventId, String value) =>
      tester.enterText(find.byKey(ValueKey('raw-$eventId')), value);

  group('calculator', () {
    Future<void> pumpCalculator(WidgetTester tester) async {
      useTallScreen(tester);
      await tester.pumpWidget(
        MaterialApp(home: PtCalculatorScreen(standard: aft)),
      );
      await tester.pumpAndSettle();
    }

    Future<void> enterMinimums(WidgetTester tester) async {
      await tester.enterText(
        find.widgetWithText(TextField, 'Age on test day'),
        '19',
      );
      // Official male 17-21 minimums (60 points each)
      await enter(tester, 'MDL', '150');
      await enter(tester, 'HRP', '15');
      await enter(tester, 'SDC', '2:28');
      await enter(tester, 'PLK', '1:30');
      await enter(tester, '2MR', '19:57');
      await tester.pumpAndSettle();
    }

    testWidgets('asks for age first', (tester) async {
      await pumpCalculator(tester);
      expect(summary(tester), 'Enter age and events');
    });

    testWidgets('minimums pass the general standard at exactly 300', (
      tester,
    ) async {
      await pumpCalculator(tester);
      await enterMinimums(tester);
      expect(summary(tester), 'PASS · 300 / 500');
      expect(find.text('Age group 17-21'), findsOneWidget);
      // Min / max hints for the profile
      expect(find.text('60 pts: 150 lb  ·  100 pts: 340 lb'), findsOneWidget);
    });

    testWidgets('a combat MOS switches to the combat standard (350)', (
      tester,
    ) async {
      await pumpCalculator(tester);
      await enterMinimums(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'MOS (optional)'),
        '11B',
      );
      await tester.pumpAndSettle();
      expect(summary(tester), 'FAIL · 300 / 500');
      expect(find.text('Total below 350'), findsOneWidget);
    });

    testWidgets('flags events under 60 and bad times', (tester) async {
      await pumpCalculator(tester);
      await enterMinimums(tester);
      await enter(tester, 'HRP', '14');
      await enter(tester, '2MR', '19:9');
      await tester.pumpAndSettle();
      expect(find.text('Use m:ss'), findsOneWidget);
      // 60 + 50 (14 reps) + 60 + 60; the invalid run time isn't counted
      expect(summary(tester), '230 points so far');
      expect(find.text('Below 60: HRP'), findsOneWidget);
    });
  });

  testWidgets('hub lists the tools and the tables in effect', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: PtHubScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Score Calculator'), findsOneWidget);
    expect(find.text('Run Lap Tracker'), findsOneWidget);
    expect(find.text('Hand-Release Push-Up'), findsOneWidget);
    expect(find.text('2:00 countdown'), findsOneWidget);
    expect(find.textContaining('effective Jun 1, 2025'), findsWidgets);
  });

  testWidgets('event timer starts ready', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EventTimerScreen(
          preset: timerPresetFor('HRP'),
          returnsTime: false,
        ),
      ),
    );
    expect(find.text('2:00.0'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('lap tracker: tap laps, finish, and score the run', (
    tester,
  ) async {
    useTallScreen(tester);
    final time = FakeTime();
    final session =
        LapSession(clock: ElapsedClock(now: time.call), lapsPerRun: 2)
          ..addRunner('SPC Fast', age: 19, sex: Sex.male)
          ..addRunner('PFC Slow', age: 19, sex: Sex.male);

    await tester.pumpWidget(
      MaterialApp(
        home: LapTrackerScreen(standard: aft, session: session),
      ),
    );
    await tester.tap(find.text('Start run'));
    await tester.pump();

    // Lap 1
    time.advance(const Duration(seconds: 400));
    await tester.tap(find.text('SPC Fast'));
    time.advance(const Duration(seconds: 100));
    await tester.tap(find.text('PFC Slow'));
    await tester.pump();
    expect(find.text('Lap 2 of 2'), findsNWidgets(2));

    // Finish: 13:22 (100 pts) and 19:58 (59 pts, below 60)
    time.advance(const Duration(seconds: 302));
    await tester.tap(find.text('SPC Fast'));
    time.advance(const Duration(seconds: 396)); // Slow finishes at 19:58
    await tester.tap(find.text('PFC Slow'));
    await tester.pumpAndSettle();

    // Everyone finished: results
    expect(find.text('RESULTS · 2 LAPS'), findsOneWidget);
    expect(find.text('13:22'), findsOneWidget);
    expect(find.text('100 pts'), findsOneWidget);
    expect(find.text('19:58'), findsOneWidget);
    expect(find.text('59 pts'), findsOneWidget);
    expect(session.clock.isRunning, isFalse);
  });
}
