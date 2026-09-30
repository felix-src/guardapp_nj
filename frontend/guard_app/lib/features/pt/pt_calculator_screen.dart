import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../core/ui.dart';
import 'event_timer_screen.dart';
import 'pt_format.dart';
import 'pt_standard.dart';
import 'pt_widgets.dart';

/// Scores a full test (or any events entered so far) for one Soldier.
class PtCalculatorScreen extends StatefulWidget {
  final PtStandard standard;

  const PtCalculatorScreen({super.key, required this.standard});

  @override
  State<PtCalculatorScreen> createState() => _PtCalculatorScreenState();
}

class _PtCalculatorScreenState extends State<PtCalculatorScreen> {
  StandardType _type = StandardType.general;
  Sex _sex = Sex.male;
  final _age = TextEditingController();
  final _mos = TextEditingController();
  late final Map<String, TextEditingController> _raw = {
    for (final e in widget.standard.events) e.id: TextEditingController(),
  };
  String _alternateId = '';
  final _alternateTime = TextEditingController();

  PtStandard get _standard => widget.standard;

  @override
  void initState() {
    super.initState();
    _alternateId = _standard.alternates.first.id;
    for (final c in [_age, _mos, _alternateTime, ..._raw.values]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_age, _mos, _alternateTime, ..._raw.values]) {
      c.dispose();
    }
    super.dispose();
  }

  /// The current profile, or null until a valid age is entered.
  PtProfile? get _profile {
    final age = int.tryParse(_age.text);
    if (age == null || _standard.ageColumn(age) == null) return null;
    return PtProfile(age: age, sex: _sex, standard: _type);
  }

  int? _rawValue(PtEvent event) {
    final text = _raw[event.id]!.text;
    return event.isTimed ? parseTime(text) : int.tryParse(text);
  }

  void _onMosChanged(String mos) {
    final trimmed = mos.trim();
    if (trimmed.length < 3) return;
    setState(() {
      _type = _standard.isCombatMos(trimmed)
          ? StandardType.combat
          : StandardType.general;
    });
  }

  void _clear() {
    for (final c in _raw.values) {
      c.clear();
    }
    _alternateTime.clear();
  }

  Future<void> _openTimer(PtEvent event) async {
    final seconds = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => EventTimerScreen(
          preset: timerPresetFor(event.id),
          returnsTime: event.isTimed,
          standard: _standard,
          profile: _profile,
        ),
      ),
    );
    if (seconds != null) _raw[event.id]!.text = formatSeconds(seconds);
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final column = profile == null ? null : _standard.ageColumn(profile.age);
    final useMale = profile != null && PtStandard.usesMaleColumn(profile);

    final raw = <String, int>{
      for (final e in _standard.events)
        if (_rawValue(e) case final int v) e.id: v,
    };
    final result = profile == null ? null : _standard.score(raw, profile);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_standard.shortName} Calculator'),
        actions: [TextButton(onPressed: _clear, child: const Text('Clear'))],
      ),
      bottomNavigationBar: _SummaryBar(
        standard: _standard,
        result: result,
        eventsEntered: raw.length,
        needsAge: profile == null,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          children: [
            GroupedSection(
              title: 'Soldier',
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StandardPicker(
                        standard: _standard,
                        value: _type,
                        onChanged: (v) => setState(() => _type = v),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _mos,
                        decoration: const InputDecoration(
                          labelText: 'MOS (optional)',
                          hintText: 'e.g. 11B — sets the standard',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        onChanged: _onMosChanged,
                      ),
                      const SizedBox(height: 16),
                      Segmented<Sex>(
                        value: _sex,
                        options: const {Sex.male: 'Male', Sex.female: 'Female'},
                        onChanged: (v) => setState(() => _sex = v),
                      ),
                      if (_type == StandardType.combat)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'The combat standard scores everyone on the same '
                            'table.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _age,
                        decoration: InputDecoration(
                          labelText: 'Age on test day',
                          helperText: column == null
                              ? null
                              : 'Age group ${_standard.ageGroups[column].label}',
                          errorText: _age.text.isNotEmpty && profile == null
                              ? 'Age groups start at 17'
                              : null,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            GroupedSection(
              title: 'Events',
              children: [
                for (final (i, event) in _standard.events.indexed)
                  _EventRow(
                    event: event,
                    controller: _raw[event.id]!,
                    gradient: GuardColors
                        .badgeGradients[i % GuardColors.badgeGradients.length],
                    score: result?.events
                        .where((s) => s.event.id == event.id)
                        .firstOrNull,
                    minimum: _standard.minPointsPerEvent,
                    minRaw: column == null
                        ? null
                        : event.thresholdFor(
                            _standard.minPointsPerEvent,
                            column: column,
                            useMale: useMale,
                          ),
                    maxRaw: column == null
                        ? null
                        : event.thresholdFor(
                            100,
                            column: column,
                            useMale: useMale,
                          ),
                    invalid:
                        _raw[event.id]!.text.isNotEmpty &&
                        _rawValue(event) == null,
                    onTimer: event.id == 'MDL' ? null : () => _openTimer(event),
                  ),
              ],
            ),
            _AlternateSection(
              standard: _standard,
              selectedId: _alternateId,
              controller: _alternateTime,
              column: column,
              useMale: useMale,
              onSelected: (id) => setState(() => _alternateId = id),
            ),
            StandardSourceNote(standard: _standard),
          ],
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final PtEvent event;
  final TextEditingController controller;
  final Gradient gradient;
  final EventScore? score;
  final int minimum;
  final int? minRaw;
  final int? maxRaw;
  final bool invalid;
  final VoidCallback? onTimer;

  const _EventRow({
    required this.event,
    required this.controller,
    required this.gradient,
    required this.score,
    required this.minimum,
    required this.minRaw,
    required this.maxRaw,
    required this.invalid,
    this.onTimer,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.65);
    final min = minRaw;
    final max = maxRaw;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: IconBadge(icon: eventIcon(event.id), gradient: gradient),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: ValueKey('raw-${event.id}'),
                        controller: controller,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: switch (event.unit) {
                            EventUnit.lbs => 'Weight',
                            EventUnit.reps => 'Reps',
                            EventUnit.time => 'm:ss',
                          },
                          suffixText: switch (event.unit) {
                            EventUnit.lbs => 'lb',
                            EventUnit.reps => 'reps',
                            EventUnit.time => null,
                          },
                          errorText: invalid ? 'Use m:ss' : null,
                        ),
                        keyboardType: event.isTimed
                            ? const TextInputType.numberWithOptions()
                            : TextInputType.number,
                        inputFormatters: event.isTimed
                            ? [TimeInputFormatter()]
                            : [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                      ),
                    ),
                    if (onTimer != null)
                      IconButton(
                        tooltip: '${event.name} timer',
                        icon: const Icon(Icons.timer_outlined),
                        onPressed: onTimer,
                      ),
                  ],
                ),
                if (min != null && max != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$minimum pts: ${formatRaw(event, min)}  ·  '
                    '100 pts: ${formatRaw(event, max)}',
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: PointsBadge(points: score?.points, minimum: minimum),
          ),
        ],
      ),
    );
  }
}

class _AlternateSection extends StatelessWidget {
  final PtStandard standard;
  final String selectedId;
  final TextEditingController controller;
  final int? column;
  final bool useMale;
  final ValueChanged<String> onSelected;

  const _AlternateSection({
    required this.standard,
    required this.selectedId,
    required this.controller,
    required this.column,
    required this.useMale,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final alternate = standard.alternates.firstWhere((a) => a.id == selectedId);
    final col = column;
    final max = col == null
        ? null
        : alternate.maxSeconds(column: col, useMale: useMale);
    final seconds = parseTime(controller.text);
    final go = (max != null && seconds != null) ? seconds <= max : null;

    return GroupedSection(
      title: 'Alternate aerobic event (profile)',
      footer:
          'Go / No-Go. For Soldiers with a profile that allows an '
          'alternate aerobic event.',
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedId,
                decoration: const InputDecoration(labelText: 'Event'),
                items: [
                  for (final a in standard.alternates)
                    DropdownMenuItem(value: a.id, child: Text(a.name)),
                ],
                onChanged: (id) {
                  if (id != null) onSelected(id);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Time (m:ss)',
                        helperText: max == null
                            ? 'Enter age above for the standard'
                            : 'GO at ${formatSeconds(max)} or faster',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(),
                      inputFormatters: [TimeInputFormatter()],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: Text(
                      go == null ? '—' : (go ? 'GO' : 'NO-GO'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: go == null
                            ? colors.onSurface.withValues(alpha: 0.3)
                            : go
                            ? GuardColors.forest
                            : colors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Total, pass/fail, and why, pinned to the bottom of the calculator.
class _SummaryBar extends StatelessWidget {
  final PtStandard standard;
  final PtResult? result;
  final int eventsEntered;
  final bool needsAge;

  const _SummaryBar({
    required this.standard,
    required this.result,
    required this.eventsEntered,
    required this.needsAge,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final r = result;
    final allEntered = eventsEntered == standard.events.length;

    final String headline;
    final String detail;
    Color? accent;
    if (needsAge || r == null) {
      headline = 'Enter age and events';
      detail = 'Scores update as you type.';
    } else {
      final failed = r.failedEvents.map((e) => e.event.id).join(', ');
      if (!allEntered) {
        headline = '${r.total} points so far';
        detail = failed.isEmpty
            ? '$eventsEntered of ${standard.events.length} events entered'
            : 'Below ${r.minPerEvent}: $failed';
        accent = failed.isEmpty ? null : colors.error;
      } else if (r.passed) {
        headline = 'PASS · ${r.total} / ${standard.events.length * 100}';
        detail = 'Needs ${r.minPerEvent}+ per event and ${r.minTotal}+ total';
        accent = GuardColors.forest;
      } else {
        headline = 'FAIL · ${r.total} / ${standard.events.length * 100}';
        detail = [
          if (failed.isNotEmpty) 'Below ${r.minPerEvent}: $failed',
          if (!r.totalMet) 'Total below ${r.minTotal}',
        ].join(' · ');
        accent = colors.error;
      }
    }

    return Material(
      color: colors.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              if (accent != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    r!.passed ? Icons.check_circle : Icons.cancel,
                    color: accent,
                    size: 32,
                  ),
                ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      key: const ValueKey('pt-summary'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    Text(
                      detail,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
