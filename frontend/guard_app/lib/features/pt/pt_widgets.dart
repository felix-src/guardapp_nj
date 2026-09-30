import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import 'pt_standard.dart';

IconData eventIcon(String eventId) => switch (eventId) {
  'MDL' => Icons.fitness_center,
  'HRP' => Icons.sports_gymnastics,
  'SDC' => Icons.bolt,
  'PLK' => Icons.accessibility_new,
  '2MR' => Icons.directions_run,
  _ => Icons.timer,
};

/// iOS-style segmented control for a small set of options.
class Segmented<T extends Object> extends StatelessWidget {
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  const Segmented({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoSlidingSegmentedControl<T>(
      groupValue: value,
      thumbColor: Theme.of(context).colorScheme.surface,
      onValueChanged: (v) {
        if (v != null) onChanged(v);
      },
      children: {
        for (final entry in options.entries)
          entry.key: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(entry.value),
          ),
      },
    );
  }
}

/// General vs combat standard, with what each means.
class StandardPicker extends StatelessWidget {
  final PtStandard standard;
  final StandardType value;
  final ValueChanged<StandardType> onChanged;

  const StandardPicker({
    super.key,
    required this.standard,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.72);
    final combat = value == StandardType.combat;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Segmented<StandardType>(
          value: value,
          options: const {
            StandardType.general: 'General',
            StandardType.combat: 'Combat',
          },
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        Text(
          combat
              ? 'Sex-neutral, age-normed. ${standard.minPointsPerEvent}+ '
                    'points per event and ${standard.minTotalCombat}+ total. '
                    'For combat MOSs: ${standard.combatMos.join(', ')}.'
              : 'Age- and sex-normed. ${standard.minPointsPerEvent}+ points '
                    'per event and ${standard.minTotalGeneral}+ total.',
          style: TextStyle(fontSize: 13, color: muted, height: 1.3),
        ),
      ],
    );
  }
}

/// Points for one event, green at or above the minimum, red below.
class PointsBadge extends StatelessWidget {
  final int? points;
  final int minimum;

  const PointsBadge({super.key, required this.points, required this.minimum});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final p = points;
    final ok = p != null && p >= minimum;
    final color = p == null
        ? colors.onSurface.withValues(alpha: 0.3)
        : ok
        ? GuardColors.forest
        : colors.error;

    return SizedBox(
      width: 64,
      child: Column(
        children: [
          Text(
            p?.toString() ?? '—',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            'points',
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

/// Footer naming the official tables a screen is based on.
class StandardSourceNote extends StatelessWidget {
  final PtStandard standard;

  const StandardSourceNote({super.key, required this.standard});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 4, 32, 24),
      child: Text(
        [
          ...standard.notes,
          'Based on the official ${standard.sourceTitle} '
              '(${standard.shortName}, effective '
              '${formatDate(standard.effective)}). Unofficial calculator: '
              'your graded scorecard is the record.',
        ].join('\n\n'),
        style: TextStyle(fontSize: 12, color: muted, height: 1.3),
      ),
    );
  }
}
