import 'package:flutter/services.dart';

import 'pt_standard.dart';

/// 802 -> "13:22"
String formatSeconds(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// Stopwatch display with tenths: "13:22.4"; hours when needed.
String formatElapsed(Duration d) {
  final tenths = (d.inMilliseconds % 1000) ~/ 100;
  final s = d.inSeconds % 60;
  final m = d.inMinutes % 60;
  final h = d.inHours;
  final mm = h > 0 ? m.toString().padLeft(2, '0') : '$m';
  return '${h > 0 ? '$h:' : ''}$mm:${s.toString().padLeft(2, '0')}.$tenths';
}

/// Parses "13:22", "1322", or "92" (seconds) into seconds. Null if invalid.
int? parseTime(String input) {
  final text = input.trim();
  if (text.isEmpty) return null;

  if (text.contains(':')) {
    final parts = text.split(':');
    if (parts.length != 2) return null;
    final m = int.tryParse(parts[0]);
    final s = int.tryParse(parts[1]);
    if (m == null || s == null || s >= 60 || parts[1].length != 2) return null;
    return m * 60 + s;
  }

  final digits = int.tryParse(text);
  if (digits == null) return null;
  // "1322" -> 13:22; up to two digits are plain seconds
  if (text.length <= 2) return digits;
  final s = digits % 100;
  if (s >= 60) return null;
  return (digits ~/ 100) * 60 + s;
}

/// A raw score as the tables show it: "340 lb", "58 reps", "13:22".
String formatRaw(PtEvent event, int raw) => switch (event.unit) {
  EventUnit.lbs => '$raw lb',
  EventUnit.reps => '$raw reps',
  EventUnit.time => formatSeconds(raw),
};

/// Time fields: digits with at most one colon ("13:22" or "1322"). Edits
/// that would break that shape are ignored.
class TimeInputFormatter extends TextInputFormatter {
  static final _shape = RegExp(r'^\d{0,3}:?\d{0,2}$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => _shape.hasMatch(newValue.text) ? newValue : oldValue;
}
