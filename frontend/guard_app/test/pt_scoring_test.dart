// Expected values come straight from the official "Army Fitness Test Score
// Tables" (approved 15 May 2025, effective 1 June 2025).
import 'package:flutter_test/flutter_test.dart';
import 'package:guard_app/features/pt/pt_format.dart';
import 'package:guard_app/features/pt/pt_standard.dart';
import 'package:guard_app/features/pt/standards.dart';

const male17 = PtProfile(
  age: 19,
  sex: Sex.male,
  standard: StandardType.general,
);
const female17 = PtProfile(
  age: 19,
  sex: Sex.female,
  standard: StandardType.general,
);
const femaleCombat17 = PtProfile(
  age: 19,
  sex: Sex.female,
  standard: StandardType.combat,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PtStandard aft;

  setUpAll(() async {
    aft = await PtStandards.current(date: DateTime(2026, 9, 29));
  });

  int points(String event, int raw, PtProfile p) =>
      aft.scoreEvent(aft.event(event), raw, p).points;

  test('loads the AFT tables in effect in 2026', () {
    expect(aft.shortName, 'AFT');
    expect(aft.effective, DateTime(2025, 6, 1));
    expect(aft.events.map((e) => e.id), ['MDL', 'HRP', 'SDC', 'PLK', '2MR']);
    expect(aft.minPointsPerEvent, 60);
    expect(aft.minTotal(StandardType.general), 300);
    expect(aft.minTotal(StandardType.combat), 350);
  });

  group('deadlift (more is better)', () {
    test('official thresholds, male 17-21', () {
      expect(points('MDL', 340, male17), 100);
      expect(points('MDL', 150, male17), 60);
    });

    test('a "---" row cannot be earned: 335 lb scores 98, not 99', () {
      expect(points('MDL', 339, male17), 98);
      expect(points('MDL', 330, male17), 98);
    });

    test('between table rows rounds down to the row met', () {
      expect(points('MDL', 149, male17), 50); // 60 needs 150, 50 needs 130
      expect(points('MDL', 79, male17), 0);
    });

    test('female column, 17-21', () {
      expect(points('MDL', 220, female17), 100);
      expect(points('MDL', 120, female17), 60);
    });

    test('the combat standard uses the sex-neutral (male) column', () {
      expect(points('MDL', 150, femaleCombat17), 60);
      expect(points('MDL', 340, femaleCombat17), 100);
      expect(points('MDL', 120, femaleCombat17), lessThan(60));
    });
  });

  group('timed events (less is better)', () {
    test('sprint-drag-carry, male 17-21', () {
      expect(points('SDC', parseTime('1:29')!, male17), 100);
      expect(points('SDC', parseTime('1:30')!, male17), 99); // 99 = 1:31
      expect(points('SDC', parseTime('2:28')!, male17), 60);
      expect(points('SDC', parseTime('2:29')!, male17), 59);
    });

    test('two-mile run, male 17-21', () {
      expect(points('2MR', parseTime('13:22')!, male17), 100);
      expect(points('2MR', parseTime('19:57')!, male17), 60);
      expect(points('2MR', parseTime('19:58')!, male17), 59); // 59 = 20:00
    });

    test('plank (more time is better)', () {
      expect(points('PLK', parseTime('3:40')!, male17), 100);
      expect(points('PLK', parseTime('1:30')!, male17), 60);
      expect(points('PLK', parseTime('1:29')!, male17), lessThan(59));
    });
  });

  test('age groups follow the tables (17-21 ... 57-61, 62+)', () {
    expect(aft.ageColumn(17), 0);
    expect(aft.ageColumn(21), 0);
    expect(aft.ageColumn(22), 1);
    expect(aft.ageColumn(61), 8);
    expect(aft.ageColumn(62), 9);
    expect(aft.ageColumn(70), 9);
    expect(aft.ageColumn(16), isNull);

    // Official 32-36 male: 61 points = 150 lb, 60 points = 140 lb
    const male34 = PtProfile(
      age: 34,
      sex: Sex.male,
      standard: StandardType.general,
    );
    expect(points('MDL', 150, male34), 61);
    expect(points('MDL', 140, male34), 60);
  });

  test('minimum and maximum raw scores for display', () {
    final mdl = aft.event('MDL');
    expect(mdl.thresholdFor(60, column: 0, useMale: true), 150);
    expect(mdl.thresholdFor(100, column: 0, useMale: true), 340);
    // 99 can't be earned, so the easiest way to reach 99+ is 100's 340 lb
    expect(mdl.thresholdFor(99, column: 0, useMale: true), 340);
    expect(
      aft.event('2MR').thresholdFor(60, column: 0, useMale: true),
      parseTime('19:57'),
    );
  });

  group('pass / fail', () {
    Map<String, int> rawFor(int pts, PtProfile p) => {
      for (final e in aft.events)
        e.id: e.thresholdFor(
          pts,
          column: aft.ageColumn(p.age)!,
          useMale: PtStandard.usesMaleColumn(p),
        )!,
    };

    test('60 in every event passes the general standard (300)', () {
      final result = aft.score(rawFor(60, male17), male17);
      expect(result.total, 300);
      expect(result.passed, isTrue);
    });

    test('60 in every event fails the combat standard (needs 350)', () {
      const combat = PtProfile(
        age: 19,
        sex: Sex.male,
        standard: StandardType.combat,
      );
      final result = aft.score(rawFor(60, combat), combat);
      expect(result.total, 300);
      expect(result.failedEvents, isEmpty);
      expect(result.totalMet, isFalse);
      expect(result.passed, isFalse);
    });

    test('one event under 60 fails even with a high total', () {
      final raw = rawFor(100, male17)..['HRP'] = 14; // 60 needs 15
      final result = aft.score(raw, male17);
      expect(result.total, greaterThan(400));
      expect(result.failedEvents.single.event.id, 'HRP');
      expect(result.passed, isFalse);
    });

    test('a partial entry scores only the events given', () {
      final result = aft.score({'MDL': 340}, male17);
      expect(result.events.single.points, 100);
      expect(result.total, 100);
    });
  });

  test('alternate aerobic events are Go / No-Go', () {
    final walk = aft.alternates.firstWhere((a) => a.id == 'WALK');
    expect(walk.isGo(parseTime('31:00')!, column: 0, useMale: true), isTrue);
    expect(walk.isGo(parseTime('31:01')!, column: 0, useMale: true), isFalse);
    expect(walk.maxSeconds(column: 9, useMale: false), parseTime('36:00'));
  });

  group('time entry', () {
    test('parses common formats', () {
      expect(parseTime('13:22'), 802);
      expect(parseTime('1322'), 802);
      expect(parseTime('1:29'), 89);
      expect(parseTime('129'), 89);
      expect(parseTime('45'), 45);
    });

    test('rejects impossible times', () {
      expect(parseTime('13:75'), isNull);
      expect(parseTime('1375'), isNull);
      expect(parseTime('1:5'), isNull);
      expect(parseTime(''), isNull);
      expect(parseTime('abc'), isNull);
    });

    test('formats times', () {
      expect(formatSeconds(802), '13:22');
      expect(formatSeconds(89), '1:29');
      expect(
        formatElapsed(
          const Duration(minutes: 13, seconds: 22, milliseconds: 460),
        ),
        '13:22.4',
      );
      expect(
        formatElapsed(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03.0',
      );
    });
  });
}
