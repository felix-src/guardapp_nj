import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import 'elapsed_clock.dart';
import 'keep_screen_on.dart';
import 'pt_format.dart';
import 'pt_standard.dart';
import 'pt_widgets.dart';

enum TimerMode { countdown, stopwatch }

class TimerPreset {
  final String id;
  final String title;
  final TimerMode mode;

  /// Countdown length, or the event's time cap for a stopwatch.
  final Duration? limit;
  final String instructions;

  /// Event whose score to show live (e.g. plank), if any.
  final String? scoredEventId;

  const TimerPreset({
    required this.id,
    required this.title,
    required this.mode,
    required this.instructions,
    this.limit,
    this.scoredEventId,
  });
}

// Timed parts of the AFT (event rules from army.mil/aft).
const timerPresets = [
  TimerPreset(
    id: 'HRP',
    title: 'Hand-Release Push-Up',
    mode: TimerMode.countdown,
    limit: Duration(minutes: 2),
    instructions: 'Count repetitions for 2 minutes.',
  ),
  TimerPreset(
    id: 'SDC',
    title: 'Sprint-Drag-Carry',
    mode: TimerMode.stopwatch,
    limit: Duration(minutes: 4),
    instructions: '5 x 50 m: sprint, drag, lateral, carry, sprint. 4:00 limit.',
    scoredEventId: 'SDC',
  ),
  TimerPreset(
    id: 'PLK',
    title: 'Plank',
    mode: TimerMode.stopwatch,
    instructions: 'Stop when the Soldier breaks the straight-line position.',
    scoredEventId: 'PLK',
  ),
  TimerPreset(
    id: '2MR',
    title: '2-Mile Run',
    mode: TimerMode.stopwatch,
    instructions: 'One runner. For several runners, use the Run Lap Tracker.',
    scoredEventId: '2MR',
  ),
  TimerPreset(
    id: 'STOPWATCH',
    title: 'Stopwatch',
    mode: TimerMode.stopwatch,
    instructions: 'General-purpose stopwatch.',
  ),
];

TimerPreset timerPresetFor(String id) =>
    timerPresets.firstWhere((p) => p.id == id);

/// Countdown or stopwatch for one event. Keeps the screen awake while
/// running. With [returnsTime], "Use time" pops the whole seconds shown.
class EventTimerScreen extends StatefulWidget {
  final TimerPreset preset;
  final bool returnsTime;

  /// When both are given, shows the live score for [TimerPreset.scoredEventId].
  final PtStandard? standard;
  final PtProfile? profile;

  const EventTimerScreen({
    super.key,
    required this.preset,
    this.returnsTime = false,
    this.standard,
    this.profile,
  });

  @override
  State<EventTimerScreen> createState() => _EventTimerScreenState();
}

class _EventTimerScreenState extends State<EventTimerScreen> {
  final _clock = ElapsedClock();
  Timer? _ticker;
  final Set<int> _alerted = {};

  TimerPreset get _preset => widget.preset;
  bool get _isCountdown => _preset.mode == TimerMode.countdown;

  @override
  void dispose() {
    _ticker?.cancel();
    keepScreenOn(false);
    super.dispose();
  }

  void _start() {
    if (_isCountdown && _remaining == Duration.zero) return;
    _clock.start();
    keepScreenOn(true);
    HapticFeedback.mediumImpact();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
    setState(() {});
  }

  void _stop() {
    _clock.stop();
    _ticker?.cancel();
    keepScreenOn(false);
    HapticFeedback.mediumImpact();
    setState(() {});
  }

  void _reset() {
    _clock.reset();
    _alerted.clear();
    setState(() {});
  }

  void _tick() {
    if (_isCountdown) {
      final left = _remaining.inSeconds;
      // Light warning taps at 30 and 10 seconds left
      for (final mark in const [30, 10]) {
        if (left < mark && _alerted.add(mark)) HapticFeedback.lightImpact();
      }
      if (_remaining == Duration.zero) {
        _stop();
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.alert);
        return;
      }
    } else if (_preset.limit case final limit?) {
      if (_clock.elapsed >= limit && _alerted.add(-1)) {
        HapticFeedback.heavyImpact();
      }
    }
    setState(() {});
  }

  Duration get _remaining {
    final left = _preset.limit! - _clock.elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  int? get _livePoints {
    final standard = widget.standard;
    final profile = widget.profile;
    final eventId = _preset.scoredEventId;
    if (standard == null || profile == null || eventId == null) return null;
    if (standard.ageColumn(profile.age) == null) return null;
    return standard
        .scoreEvent(standard.event(eventId), _clock.elapsed.inSeconds, profile)
        .points;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final elapsed = _clock.elapsed;
    final shown = _isCountdown ? _remaining : elapsed;
    final overLimit =
        !_isCountdown && _preset.limit != null && elapsed >= _preset.limit!;
    final timeUp = _isCountdown && _clock.hasStarted && shown == Duration.zero;
    final points = _livePoints;

    return Scaffold(
      appBar: AppBar(title: Text(_preset.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                _preset.instructions,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.72),
                  height: 1.3,
                ),
              ),
              const Spacer(),
              FittedBox(
                child: Text(
                  timeUp ? 'TIME' : formatElapsed(shown),
                  style: TextStyle(
                    fontSize: 88,
                    fontWeight: FontWeight.w300,
                    color: timeUp || overLimit ? colors.error : null,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (overLimit)
                Text(
                  'Time limit (${formatSeconds(_preset.limit!.inSeconds)}) '
                  'reached',
                  style: TextStyle(color: colors.error),
                ),
              if (points != null && widget.standard != null) ...[
                const SizedBox(height: 12),
                PointsBadge(
                  points: _clock.hasStarted ? points : null,
                  minimum: widget.standard!.minPointsPerEvent,
                ),
              ],
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _RoundButton(
                    label: 'Reset',
                    color: colors.onSurface.withValues(alpha: 0.12),
                    textColor: colors.onSurface,
                    onPressed: !_clock.isRunning && _clock.hasStarted
                        ? _reset
                        : null,
                  ),
                  _clock.isRunning
                      ? _RoundButton(
                          label: 'Stop',
                          color: colors.error,
                          textColor: Colors.white,
                          onPressed: _stop,
                        )
                      : _RoundButton(
                          label: _clock.hasStarted ? 'Resume' : 'Start',
                          color: GuardColors.forest,
                          textColor: Colors.white,
                          onPressed: timeUp ? null : _start,
                        ),
                ],
              ),
              const SizedBox(height: 24),
              if (widget.returnsTime)
                ElevatedButton(
                  onPressed: !_clock.isRunning && elapsed.inSeconds > 0
                      ? () => Navigator.pop(context, elapsed.inSeconds)
                      : null,
                  child: Text(
                    elapsed.inSeconds > 0
                        ? 'Use ${formatSeconds(elapsed.inSeconds)}'
                        : 'Use time',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Large round button, like the iOS Clock app.
class _RoundButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onPressed;

  const _RoundButton({
    required this.label,
    required this.color,
    required this.textColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      width: 96,
      height: 96,
      child: FilledButton(
        style: FilledButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: color,
          foregroundColor: textColor,
          disabledBackgroundColor: color.withValues(alpha: 0.35),
          disabledForegroundColor: textColor.withValues(alpha: 0.5),
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: enabled ? textColor : null,
          ),
        ),
      ),
    );
  }
}
