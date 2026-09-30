import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen from auto-locking while timing (a lap can take longer
/// than the phone's auto-lock). Best effort: a failure here must never
/// interrupt a timer.
void keepScreenOn(bool on) {
  try {
    WakelockPlus.toggle(enable: on).catchError((Object _) {});
  } catch (_) {
    // Plugin unavailable (tests, unsupported platform)
  }
}
