/// A start/stop clock measured from wall-clock timestamps rather than by
/// counting ticks, so it stays correct while the phone's screen is off or
/// the app is in the background (a tick-based stopwatch can pause then).
class ElapsedClock {
  /// Replaceable in tests.
  final DateTime Function() now;

  ElapsedClock({DateTime Function()? now}) : now = now ?? DateTime.now;

  DateTime? _startedAt;
  Duration _banked = Duration.zero;

  bool get isRunning => _startedAt != null;
  bool get hasStarted => isRunning || _banked > Duration.zero;

  Duration get elapsed {
    final started = _startedAt;
    return started == null ? _banked : _banked + now().difference(started);
  }

  void start() => _startedAt ??= now();

  void stop() {
    final started = _startedAt;
    if (started == null) return;
    _banked += now().difference(started);
    _startedAt = null;
  }

  void reset() {
    _startedAt = null;
    _banked = Duration.zero;
  }
}
