import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import 'event_timer_screen.dart';
import 'lap_tracker_screen.dart';
import 'pt_calculator_screen.dart';
import 'pt_standard.dart';
import 'pt_widgets.dart';
import 'standards.dart';

/// Entry point from Home: score calculator, event timers, and the run lap
/// tracker for the fitness test currently in effect. Works offline.
class PtHubScreen extends StatefulWidget {
  const PtHubScreen({super.key});

  @override
  State<PtHubScreen> createState() => _PtHubScreenState();
}

class _PtHubScreenState extends State<PtHubScreen> {
  late final Future<PtStandard> _standard = PtStandards.current();

  void _open(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PT Test')),
      body: FutureBuilder<PtStandard>(
        future: _standard,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load the score tables'));
          }
          final standard = snapshot.data;
          if (standard == null) {
            return const Center(child: CupertinoActivityIndicator());
          }

          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
                child: Text(
                  '${standard.name}: ${standard.events.map((e) => e.name).join(', ')}. '
                  'Tables effective ${formatDate(standard.effective)}.',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.72),
                    height: 1.3,
                  ),
                ),
              ),
              GroupedSection(
                children: [
                  NavRow(
                    icon: Icons.calculate,
                    gradient: GuardColors.badgeGradients[0],
                    title: 'Score Calculator',
                    subtitle: 'Points, pass/fail, general or combat',
                    onTap: () => _open(PtCalculatorScreen(standard: standard)),
                  ),
                  NavRow(
                    icon: Icons.directions_run,
                    gradient: GuardColors.badgeGradients[3],
                    title: 'Run Lap Tracker',
                    subtitle: 'Time several runners, one tap per lap',
                    onTap: () => _open(LapTrackerScreen(standard: standard)),
                  ),
                ],
              ),
              GroupedSection(
                title: 'Event timers',
                children: [
                  for (final (i, preset) in timerPresets.indexed)
                    NavRow(
                      icon: eventIcon(preset.id),
                      gradient:
                          GuardColors.badgeGradients[(i + 1) %
                              GuardColors.badgeGradients.length],
                      title: preset.title,
                      subtitle: preset.mode == TimerMode.countdown
                          ? '${preset.limit!.inMinutes}:00 countdown'
                          : preset.limit != null
                          ? 'Stopwatch · ${preset.limit!.inMinutes}:00 limit'
                          : 'Stopwatch',
                      onTap: () => _open(EventTimerScreen(preset: preset)),
                    ),
                ],
              ),
              StandardSourceNote(standard: standard),
            ],
          );
        },
      ),
    );
  }
}
