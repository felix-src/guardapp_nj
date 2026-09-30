import 'elapsed_clock.dart';
import 'pt_standard.dart';

class Runner {
  final int id;
  String name;

  /// Optional, to score the run on the tables.
  int? age;
  Sex? sex;

  /// Cumulative race time at each lap tap; the last one is the finish.
  final List<Duration> laps = [];
  bool didNotFinish = false;

  Runner({required this.id, required this.name, this.age, this.sex});

  bool get canBeScored => age != null && sex != null;
}

/// One grader timing several runners on a lap course: a single race clock
/// (mass start) and a tap per runner per lap. Lives only in memory on this
/// phone; nothing is uploaded.
class LapSession {
  final ElapsedClock clock;
  int lapsPerRun;

  /// Taps closer together than this for the same runner are treated as an
  /// accidental double tap.
  final Duration minLapGap;

  final List<Runner> runners = [];
  final List<int> _tapHistory = []; // runner ids, for undo
  int _nextId = 1;

  LapSession({
    ElapsedClock? clock,
    this.lapsPerRun = 8,
    this.minLapGap = const Duration(seconds: 3),
  }) : clock = clock ?? ElapsedClock();

  Runner addRunner(String name, {int? age, Sex? sex}) {
    final runner = Runner(id: _nextId++, name: name, age: age, sex: sex);
    runners.add(runner);
    return runner;
  }

  void removeRunner(Runner runner) {
    runners.remove(runner);
    _tapHistory.removeWhere((id) => id == runner.id);
  }

  bool isFinished(Runner r) => r.laps.length >= lapsPerRun;

  bool get allDone =>
      runners.isNotEmpty &&
      runners.every((r) => isFinished(r) || r.didNotFinish);

  /// Records a lap for [runner] at the current race time. Returns false if
  /// ignored: clock not running, runner done, or a double tap.
  bool recordLap(Runner runner) {
    if (!clock.isRunning || isFinished(runner) || runner.didNotFinish) {
      return false;
    }
    final now = clock.elapsed;
    if (runner.laps.isNotEmpty && now - runner.laps.last < minLapGap) {
      return false;
    }
    runner.laps.add(now);
    _tapHistory.add(runner.id);
    if (allDone) clock.stop();
    return true;
  }

  /// Removes the most recent lap tap (any runner). Returns that runner.
  Runner? undoLastLap() {
    if (_tapHistory.isEmpty) return null;
    final id = _tapHistory.removeLast();
    final runner = runners.firstWhere((r) => r.id == id);
    runner.laps.removeLast();
    return runner;
  }

  Duration? finishTime(Runner r) => isFinished(r) ? r.laps.last : null;

  /// Time of each lap on its own (not cumulative).
  List<Duration> splits(Runner r) => [
    for (var i = 0; i < r.laps.length; i++)
      r.laps[i] - (i == 0 ? Duration.zero : r.laps[i - 1]),
  ];

  /// Finishers fastest first, then runners still going (most laps first),
  /// then DNFs.
  List<Runner> standings() {
    int rank(Runner r) => isFinished(r) ? 0 : (r.didNotFinish ? 2 : 1);
    return [...runners]..sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      if (isFinished(a)) return a.laps.last.compareTo(b.laps.last);
      return b.laps.length.compareTo(a.laps.length);
    });
  }

  void reset() {
    clock.reset();
    _tapHistory.clear();
    for (final r in runners) {
      r.laps.clear();
      r.didNotFinish = false;
    }
  }
}
