import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../core/ui.dart';
import 'lap_session.dart';
import 'keep_screen_on.dart';
import 'pt_format.dart';
import 'pt_standard.dart';
import 'pt_widgets.dart';

/// Lets one grader time several runners on a lap course: one race clock,
/// one big tile per runner, tap it each lap. Results stay on this phone.
class LapTrackerScreen extends StatefulWidget {
  final PtStandard standard;

  /// Replaceable in tests.
  final LapSession? session;

  const LapTrackerScreen({super.key, required this.standard, this.session});

  @override
  State<LapTrackerScreen> createState() => _LapTrackerScreenState();
}

class _LapTrackerScreenState extends State<LapTrackerScreen> {
  late final LapSession _session = widget.session ?? LapSession();
  StandardType _type = StandardType.general;
  Timer? _ticker;
  bool _showResults = false;

  PtStandard get _standard => widget.standard;
  PtEvent get _run => _standard.event('2MR');
  bool get _racing => _session.clock.hasStarted && !_showResults;

  @override
  void dispose() {
    _ticker?.cancel();
    keepScreenOn(false);
    super.dispose();
  }

  void _start() {
    _session.clock.start();
    keepScreenOn(true);
    HapticFeedback.heavyImpact();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => setState(() {}),
    );
    setState(() {});
  }

  void _tapRunner(Runner runner) {
    if (!_session.recordLap(runner)) return;
    _session.isFinished(runner)
        ? HapticFeedback.heavyImpact()
        : HapticFeedback.lightImpact();
    if (_session.allDone) _finishRace();
    setState(() {});
  }

  void _undo() {
    final runner = _session.undoLastLap();
    if (runner == null) return;
    // Undoing a finish restarts the clock if the race had ended
    if (!_session.clock.isRunning && !_session.allDone) _session.clock.start();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Removed lap ${runner.laps.length + 1} for ${runner.name}',
          ),
        ),
      );
    setState(() {});
  }

  void _finishRace() {
    _session.clock.stop();
    _ticker?.cancel();
    keepScreenOn(false);
    setState(() => _showResults = true);
  }

  Future<void> _endRaceEarly() async {
    final ok = await _confirm(
      'End the run?',
      'Runners who haven\'t finished will be marked DNF.',
      'End run',
    );
    if (!ok) return;
    for (final r in _session.runners) {
      if (!_session.isFinished(r)) r.didNotFinish = true;
    }
    _finishRace();
  }

  Future<void> _newRun() async {
    final ok = await _confirm(
      'Start over?',
      'Clears all lap times. The runner list is kept.',
      'Clear times',
    );
    if (!ok) return;
    _ticker?.cancel();
    keepScreenOn(false);
    setState(() {
      _session.reset();
      _showResults = false;
    });
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _editRunner([Runner? runner]) async {
    final edited = await showDialog<_RunnerForm>(
      context: context,
      builder: (_) => _RunnerDialog(runner: runner),
    );
    if (edited == null) return;
    setState(() {
      if (runner == null) {
        _session.addRunner(edited.name, age: edited.age, sex: edited.sex);
      } else {
        runner
          ..name = edited.name
          ..age = edited.age
          ..sex = edited.sex;
      }
    });
  }

  void _quickAdd(int count) {
    setState(() {
      final start = _session.runners.length;
      for (var i = 1; i <= count; i++) {
        _session.addRunner('Runner ${start + i}');
      }
    });
  }

  /// 2-mile run points for a finisher, if their age and sex are known.
  EventScore? _scoreFor(Runner r) {
    final time = _session.finishTime(r);
    final age = r.age;
    final sex = r.sex;
    if (time == null || age == null || sex == null) return null;
    if (_standard.ageColumn(age) == null) return null;
    return _standard.scoreEvent(
      _run,
      time.inSeconds,
      PtProfile(age: age, sex: sex, standard: _type),
    );
  }

  Future<void> _copyResults() async {
    final lines = <String>[
      '${_standard.shortName} 2-Mile Run — ${_session.lapsPerRun} laps '
          '(${_type == StandardType.combat ? 'combat' : 'general'} standard)',
    ];
    for (final (i, r) in _session.standings().indexed) {
      final finish = _session.finishTime(r);
      final score = _scoreFor(r);
      lines.add(
        [
          '${i + 1}. ${r.name}',
          finish != null
              ? formatSeconds(finish.inSeconds)
              : r.didNotFinish
              ? 'DNF'
              : '${r.laps.length}/${_session.lapsPerRun} laps',
          if (score != null)
            '${score.points} pts${score.passed ? '' : ' (below ${_standard.minPointsPerEvent})'}',
        ].join('  '),
      );
    }
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Results copied')));
  }

  @override
  Widget build(BuildContext context) {
    final body = _showResults
        ? _results()
        : _session.clock.hasStarted
        ? _race()
        : _setup();

    return PopScope(
      // Don't lose a run in progress to an accidental back swipe
      canPop: !_session.clock.isRunning,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirm(
          'Leave the run?',
          'The clock and lap times will be lost.',
          'Leave',
        );
        if (!leave || !context.mounted) return;
        _session.clock.stop();
        Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Run Lap Tracker'),
          actions: [
            if (_racing)
              IconButton(
                tooltip: 'Undo last lap',
                icon: const Icon(Icons.undo),
                onPressed: _undo,
              ),
            if (_showResults)
              IconButton(
                tooltip: 'Copy results',
                icon: const Icon(Icons.copy_all),
                onPressed: _copyResults,
              ),
          ],
        ),
        body: body,
      ),
    );
  }

  Widget _setup() {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.7);

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      children: [
        GroupedSection(
          title: 'Course',
          footer:
              '2 miles is 8 laps of a 400 m track plus about 19 m; set this to '
              'match your course. Each runner\'s last tap is their finish.',
          children: [
            ListTile(
              title: const Text('Laps per runner'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _session.lapsPerRun > 1
                        ? () => setState(() => _session.lapsPerRun--)
                        : null,
                  ),
                  Text(
                    '${_session.lapsPerRun}',
                    key: const ValueKey('laps-per-runner'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _session.lapsPerRun < 50
                        ? () => setState(() => _session.lapsPerRun++)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
        GroupedSection(
          title: 'Scoring standard',
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: StandardPicker(
                standard: _standard,
                value: _type,
                onChanged: (v) => setState(() => _type = v),
              ),
            ),
          ],
        ),
        GroupedSection(
          title: 'Runners (${_session.runners.length})',
          footer:
              'Age and sex are optional; add them to see 2-mile run '
              'points. Names stay on this phone.',
          children: [
            for (final r in _session.runners)
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(r.name),
                subtitle: r.canBeScored
                    ? Text('${r.sex == Sex.male ? 'Male' : 'Female'}, ${r.age}')
                    : Text('Not scored', style: TextStyle(color: muted)),
                onTap: () => _editRunner(r),
                trailing: IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => setState(() => _session.removeRunner(r)),
                ),
              ),
            ListTile(
              leading: const Icon(Icons.person_add_alt),
              title: const Text('Add runner'),
              onTap: _editRunner,
            ),
            ListTile(
              leading: const Icon(Icons.group_add_outlined),
              title: const Text('Add 5 numbered runners'),
              onTap: () => _quickAdd(5),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton.icon(
            onPressed: _session.runners.isEmpty ? null : _start,
            icon: const Icon(Icons.flag),
            label: const Text('Start run'),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'The screen stays on during the run. Tap a runner\'s tile each '
            'time they complete a lap; a quick double tap is ignored and the '
            'undo button removes the last tap.',
            style: TextStyle(fontSize: 13, color: muted, height: 1.3),
          ),
        ),
      ],
    );
  }

  Widget _race() {
    final elapsed = _session.clock.elapsed;
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: GuardColors.heroGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                formatElapsed(elapsed),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w300,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '${_session.runners.where(_session.isFinished).length} of '
                '${_session.runners.length} finished',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.35,
            ),
            itemCount: _session.runners.length,
            itemBuilder: (context, i) {
              final r = _session.runners[i];
              return _RunnerTile(
                runner: r,
                session: _session,
                elapsed: elapsed,
                onTap: () => _tapRunner(r),
                onLongPress: () async {
                  if (_session.isFinished(r)) return;
                  final dnf = await _confirm(
                    'Mark ${r.name} DNF?',
                    'They will be listed as did not finish.',
                    'Mark DNF',
                  );
                  if (dnf) {
                    setState(() => r.didNotFinish = true);
                    if (_session.allDone) _finishRace();
                  }
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.error,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _endRaceEarly,
              child: const Text('End run'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _results() {
    final colors = Theme.of(context).colorScheme;
    final standings = _session.standings();

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      children: [
        GroupedSection(
          title: 'Results · ${_session.lapsPerRun} laps',
          children: [
            for (final (i, r) in standings.indexed)
              Builder(
                builder: (context) {
                  final finish = _session.finishTime(r);
                  final score = _scoreFor(r);
                  final splits = _session.splits(r);
                  return ExpansionTile(
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: GuardColors.tan,
                      foregroundColor: GuardColors.ink,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    title: Text(r.name),
                    subtitle: Text(
                      finish != null
                          ? formatSeconds(finish.inSeconds)
                          : r.didNotFinish
                          ? 'DNF after ${r.laps.length} laps'
                          : '${r.laps.length}/${_session.lapsPerRun} laps',
                    ),
                    trailing: score == null
                        ? null
                        : Text(
                            '${score.points} pts',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: score.passed
                                  ? GuardColors.forest
                                  : colors.error,
                            ),
                          ),
                    children: [
                      for (final (lap, split) in splits.indexed)
                        ListTile(
                          dense: true,
                          title: Text('Lap ${lap + 1}'),
                          trailing: Text(
                            '${formatElapsed(split)}   '
                            '(${formatSeconds(r.laps[lap].inSeconds)})',
                            style: const TextStyle(
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _copyResults,
                icon: const Icon(Icons.copy_all),
                label: const Text('Copy results'),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _newRun, child: const Text('New run')),
            ],
          ),
        ),
        StandardSourceNote(standard: _standard),
      ],
    );
  }
}

class _RunnerTile extends StatelessWidget {
  final Runner runner;
  final LapSession session;
  final Duration elapsed;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _RunnerTile({
    required this.runner,
    required this.session,
    required this.elapsed,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final finished = session.isFinished(runner);
    final dnf = runner.didNotFinish;
    final laps = runner.laps;
    final sinceLast = elapsed - (laps.isEmpty ? Duration.zero : laps.last);

    final background = finished
        ? GuardColors.forest
        : dnf
        ? colors.onSurface.withValues(alpha: 0.12)
        : colors.surface;
    final foreground = finished ? Colors.white : colors.onSurface;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: finished || dnf ? null : onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                runner.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                finished
                    ? formatSeconds(laps.last.inSeconds)
                    : dnf
                    ? 'DNF'
                    : 'Lap ${laps.length + 1} of ${session.lapsPerRun}',
                style: TextStyle(
                  color: foreground,
                  fontSize: finished ? 26 : 18,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                finished
                    ? 'Finished'
                    : laps.isEmpty
                    ? 'Tap at end of lap'
                    : 'Last lap ${formatSeconds(session.splits(runner).last.inSeconds)}'
                          ' · ${formatSeconds(sinceLast.inSeconds)} ago',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground.withValues(alpha: 0.75),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunnerForm {
  final String name;
  final int? age;
  final Sex? sex;

  _RunnerForm(this.name, this.age, this.sex);
}

class _RunnerDialog extends StatefulWidget {
  final Runner? runner;

  const _RunnerDialog({this.runner});

  @override
  State<_RunnerDialog> createState() => _RunnerDialogState();
}

class _RunnerDialogState extends State<_RunnerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.runner?.name);
  late final _age = TextEditingController(text: widget.runner?.age?.toString());
  late Sex? _sex = widget.runner?.sex;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.runner == null ? 'Add runner' : 'Edit runner'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name or roster #',
                hintText: 'SPC Lopez',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _age,
              decoration: const InputDecoration(labelText: 'Age (optional)'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              validator: (v) {
                final age = int.tryParse(v ?? '');
                if (v == null || v.isEmpty) return null;
                return age == null || age < 17 ? 'Age 17 or older' : null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Sex?>(
              initialValue: _sex,
              decoration: const InputDecoration(labelText: 'Sex (optional)'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Not set')),
                DropdownMenuItem(value: Sex.male, child: Text('Male')),
                DropdownMenuItem(value: Sex.female, child: Text('Female')),
              ],
              onChanged: (v) => setState(() => _sex = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _RunnerForm(_name.text.trim(), int.tryParse(_age.text), _sex),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
