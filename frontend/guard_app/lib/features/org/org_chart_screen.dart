import 'package:flutter/material.dart';

import '../../core/session.dart';
import 'org_api.dart';
import 'org_models.dart';
import 'position_picker.dart';
import 'structure_editor_screen.dart';

/// The unit's platoons and squads and who holds which position. Everyone in
/// the unit can view it; the Readiness NCO (and admins) can move people and
/// edit the structure.
class OrgChartScreen extends StatefulWidget {
  final int unitId;
  final String? unitName;

  const OrgChartScreen({super.key, required this.unitId, this.unitName});

  @override
  State<OrgChartScreen> createState() => _OrgChartScreenState();
}

class _OrgChartScreenState extends State<OrgChartScreen> {
  late Future<OrgChart> _chart;

  bool get _canManage => Session.user?.canManageUnit(widget.unitId) ?? false;

  @override
  void initState() {
    super.initState();
    _chart = OrgApi.fetchOrgChart(widget.unitId);
  }

  Future<void> _refresh() async {
    final chart = OrgApi.fetchOrgChart(widget.unitId);
    setState(() => _chart = chart);
    await chart;
  }

  Future<void> _editStructure() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StructureEditorScreen(unitId: widget.unitId),
      ),
    );
    if (mounted) _refresh();
  }

  Future<void> _movePerson(OrgChart chart, OrgMember member) async {
    final position = await showDialog<Position>(
      context: context,
      builder: (_) => _MoveDialog(chart: chart, member: member),
    );
    if (position == null || !mounted) return;

    try {
      await OrgApi.setPosition(
        widget.unitId,
        member.id,
        orgElementId: position.orgElementId,
        dutyRole: position.dutyRole,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${member.displayName} moved')));
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.unitName ?? 'Org chart'),
        actions: [
          if (_canManage)
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: 'Edit platoons & squads',
              onPressed: _editStructure,
            ),
        ],
      ),
      body: FutureBuilder<OrgChart>(
        future: _chart,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Failed to load org chart'),
                  TextButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            );
          }

          final chart = snapshot.data!;
          final onTapMember = _canManage
              ? (OrgMember m) => _movePerson(chart, m)
              : null;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (!chart.companyWide) const _NeedToKnowNote(),
                if (chart.unassigned.isNotEmpty)
                  _UnassignedCard(
                    members: chart.unassigned,
                    canManage: _canManage,
                    onTapMember: onTapMember,
                  ),
                for (final element in chart.structure)
                  _TopElementCard(element: element, onTapMember: onTapMember),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Explains a partial chart to viewers without company-wide access.
class _NeedToKnowNote extends StatelessWidget {
  const _NeedToKnowNote();

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.72);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, size: 16, color: muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'You can see Company HQ and your platoon. The full company '
              'roster is limited to leadership.',
              style: TextStyle(fontSize: 13, color: muted, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopElementCard extends StatelessWidget {
  final OrgElement element;
  final void Function(OrgMember)? onTapMember;

  const _TopElementCard({required this.element, this.onTapMember});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: element.isCompanyHq,
        leading: Icon(element.isCompanyHq ? Icons.flag : Icons.groups),
        title: Text(element.name),
        subtitle: Text(_headcountLabel(element.headcount)),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: element.isPlatoon
            ? [
                for (final child in element.children)
                  _SubElement(element: child, onTapMember: onTapMember),
              ]
            : _memberTiles(element.members, onTapMember),
      ),
    );
  }
}

class _SubElement extends StatelessWidget {
  final OrgElement element;
  final void Function(OrgMember)? onTapMember;

  const _SubElement({required this.element, this.onTapMember});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              '${element.name} · ${_headcountLabel(element.headcount)}',
              style: textTheme.titleSmall,
            ),
          ),
          ..._memberTiles(element.members, onTapMember),
        ],
      ),
    );
  }
}

class _UnassignedCard extends StatelessWidget {
  final List<OrgMember> members;
  final bool canManage;
  final void Function(OrgMember)? onTapMember;

  const _UnassignedCard({
    required this.members,
    required this.canManage,
    this.onTapMember,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: colors.tertiaryContainer,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: canManage,
        leading: const Icon(Icons.help_outline),
        title: const Text('Unassigned'),
        subtitle: Text(
          canManage
              ? 'Tap someone to give them a position'
              : _headcountLabel(members.length),
        ),
        children: _memberTiles(members, onTapMember),
      ),
    );
  }
}

List<Widget> _memberTiles(
  List<OrgMember> members,
  void Function(OrgMember)? onTapMember,
) {
  if (members.isEmpty) {
    return [const ListTile(dense: true, title: Text('Vacant'))];
  }
  return [
    for (final member in members)
      ListTile(
        dense: true,
        leading: const Icon(Icons.person_outline),
        title: Text(member.displayName),
        subtitle: member.dutyRoleLabel == null
            ? null
            : Text(member.dutyRoleLabel!),
        trailing: onTapMember == null ? null : const Icon(Icons.swap_horiz),
        onTap: onTapMember == null ? null : () => onTapMember(member),
      ),
  ];
}

String _headcountLabel(int count) =>
    count == 1 ? '1 soldier' : '$count soldiers';

/// Returns the chosen [Position] via Navigator.pop.
class _MoveDialog extends StatefulWidget {
  final OrgChart chart;
  final OrgMember member;

  const _MoveDialog({required this.chart, required this.member});

  @override
  State<_MoveDialog> createState() => _MoveDialogState();
}

class _MoveDialogState extends State<_MoveDialog> {
  final _formKey = GlobalKey<FormState>();
  Position? _position;

  @override
  void initState() {
    super.initState();
    // Start from where they are now, if anywhere
    final current = _currentElement(widget.chart.structure);
    final role = widget.member.dutyRole;
    if (current != null && role != null) {
      _position = Position(current.id, role);
    }
  }

  OrgElement? _currentElement(List<OrgElement> elements) {
    for (final el in elements) {
      if (el.members.any((m) => m.id == widget.member.id)) return el;
      final found = _currentElement(el.children);
      if (found != null) return found;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Move ${widget.member.displayName}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: PositionPicker(
              structure: widget.chart.structure,
              initial: _position,
              onChanged: (position) => _position = position,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && _position != null) {
              Navigator.pop(context, _position);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
