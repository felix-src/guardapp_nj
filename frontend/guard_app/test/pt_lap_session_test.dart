import 'package:flutter_test/flutter_test.dart';
import 'package:guard_app/features/pt/elapsed_clock.dart';
import 'package:guard_app/features/pt/lap_session.dart';

/// A clock the test moves forward by hand.
class FakeTime {
  DateTime value = DateTime(2026, 9, 29, 6);
  DateTime call() => value;
  void advance(Duration d) => value = value.add(d);
}

void main() {
  group('ElapsedClock', () {
    test('measures wall-clock time across stop and restart', () {
      final t = FakeTime();
      final clock = ElapsedClock(now: t.call);

      expect(clock.hasStarted, isFalse);
      clock.start();
      t.advance(const Duration(seconds: 90));
      expect(clock.elapsed, const Duration(seconds: 90));

      clock.stop();
      t.advance(const Duration(minutes: 5)); // stopped: doesn't count
      expect(clock.elapsed, const Duration(seconds: 90));

      clock.start();
      t.advance(const Duration(seconds: 30));
      expect(clock.elapsed, const Duration(minutes: 2));

      clock.reset();
      expect(clock.elapsed, Duration.zero);
      expect(clock.isRunning, isFalse);
    });

    test('keeps counting while the screen is off (no ticks needed)', () {
      final t = FakeTime();
      final clock = ElapsedClock(now: t.call)..start();
      t.advance(const Duration(minutes: 14, seconds: 3));
      expect(clock.elapsed, const Duration(minutes: 14, seconds: 3));
    });
  });

  group('LapSession', () {
    late FakeTime t;
    late LapSession session;

    setUp(() {
      t = FakeTime();
      session = LapSession(clock: ElapsedClock(now: t.call), lapsPerRun: 3);
    });

    test('records cumulative lap times and finishes on the last lap', () {
      final a = session.addRunner('PFC Adams');
      session.clock.start();

      t.advance(const Duration(seconds: 100));
      expect(session.recordLap(a), isTrue);
      t.advance(const Duration(seconds: 105));
      session.recordLap(a);
      t.advance(const Duration(seconds: 98));
      session.recordLap(a);

      expect(session.isFinished(a), isTrue);
      expect(session.finishTime(a), const Duration(seconds: 303));
      expect(session.splits(a), const [
        Duration(seconds: 100),
        Duration(seconds: 105),
        Duration(seconds: 98),
      ]);
      // Everyone done: the race clock stops
      expect(session.clock.isRunning, isFalse);
    });

    test('ignores taps before the start and after finishing', () {
      final a = session.addRunner('A');
      expect(session.recordLap(a), isFalse);

      session.clock.start();
      for (var i = 0; i < 3; i++) {
        t.advance(const Duration(seconds: 60));
        session.recordLap(a);
      }
      t.advance(const Duration(seconds: 60));
      expect(session.recordLap(a), isFalse);
      expect(a.laps, hasLength(3));
    });

    test('treats a quick second tap as an accidental double tap', () {
      final a = session.addRunner('A');
      session.clock.start();
      t.advance(const Duration(seconds: 80));
      expect(session.recordLap(a), isTrue);
      t.advance(const Duration(seconds: 1));
      expect(session.recordLap(a), isFalse);
      expect(a.laps, hasLength(1));
    });

    test('undo removes the most recent tap, whichever runner it was', () {
      final a = session.addRunner('A');
      final b = session.addRunner('B');
      session.clock.start();
      t.advance(const Duration(seconds: 80));
      session.recordLap(a);
      t.advance(const Duration(seconds: 5));
      session.recordLap(b);

      expect(session.undoLastLap(), same(b));
      expect(b.laps, isEmpty);
      expect(a.laps, hasLength(1));
      expect(session.undoLastLap(), same(a));
      expect(session.undoLastLap(), isNull);
    });

    test('standings: finishers fastest first, then laps done, then DNF', () {
      final slow = session.addRunner('Slow');
      final fast = session.addRunner('Fast');
      final going = session.addRunner('Going');
      final dnf = session.addRunner('DNF')..didNotFinish = true;
      session.clock.start();

      for (var lap = 0; lap < 3; lap++) {
        t.advance(const Duration(seconds: 90));
        session.recordLap(fast);
        t.advance(const Duration(seconds: 10));
        session.recordLap(slow);
        if (lap == 0) session.recordLap(going);
      }

      expect(session.standings(), [fast, slow, going, dnf]);
      expect(session.clock.isRunning, isTrue); // "Going" hasn't finished
    });

    test('reset clears laps but keeps the roster', () {
      final a = session.addRunner('A');
      session.clock.start();
      t.advance(const Duration(seconds: 70));
      session.recordLap(a);
      session.reset();
      expect(a.laps, isEmpty);
      expect(session.runners, [a]);
      expect(session.clock.hasStarted, isFalse);
      expect(session.undoLastLap(), isNull);
    });
  });
}
