import 'package:flutter/material.dart';

import 'org_api.dart';
import 'org_models.dart';

const _subElementKinds = {
  'rifle_squad': 'Rifle squad',
  'weapons_squad': 'Weapons squad / section',
  'platoon_hq': 'Platoon HQ',
};

/// Readiness NCO / admin: rename, add, and remove platoons and squads. The
/// server refuses to delete anything that still has soldiers assigned.
class StructureEditorScreen extends StatefulWidget {
  final int unitId;

  const StructureEditorScreen({super.key, required this.unitId});

  @override
  State<StructureEditorScreen> createState() => _StructureEditorScreenState();
}

class _StructureEditorScreenState extends State<StructureEditorScreen> {
  late Future<OrgChart> _chart;

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

  /// Runs [action], then reloads; shows the server's error on failure.
  Future<void> _run(Future<void> Function() action, String success) async {
    try {
      await action();
      if (!mounted) return;
      _showMessage(success);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _rename(OrgElement element) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(title: 'Rename', initialName: element.name),
    );
    if (name == null || name == element.name) return;
    await _run(
      () => OrgApi.renameElement(widget.unitId, element.id, name),
      'Renamed to $name',
    );
  }

  Future<void> _delete(OrgElement element) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${element.name}?'),
        content: Text(
          element.isPlatoon
              ? 'Its HQ and squads are deleted too. Soldiers must be moved '
                    'out first.'
              : 'Soldiers must be moved out first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(
      () => OrgApi.deleteElement(widget.unitId, element.id),
      '${element.name} deleted',
    );
  }

  Future<void> _addPlatoon() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NameDialog(
        title: 'Add platoon',
        hint: '4th Platoon',
        note: 'A Platoon HQ is added automatically.',
      ),
    );
    if (name == null) return;
    await _run(
      () => OrgApi.addElement(widget.unitId, name: name, kind: 'platoon'),
      '$name added',
    );
  }

  Future<void> _addToPlatoon(OrgElement platoon) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _AddSubElementDialog(platoonName: platoon.name),
    );
    if (result == null) return;
    final (name, kind) = result;
    await _run(
      () => OrgApi.addElement(
        widget.unitId,
        name: name,
        kind: kind,
        parentId: platoon.id,
      ),
      '$name added to ${platoon.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Platoons & squads')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPlatoon,
        icon: const Icon(Icons.add),
        label: const Text('Add platoon'),
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
                  const Text('Failed to load structure'),
                  TextButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              for (final top in snapshot.data!.structure) ...[
                _ElementTile(
                  element: top,
                  depth: 0,
                  onRename: () => _rename(top),
                  onDelete: top.isCompanyHq ? null : () => _delete(top),
                  onAdd: top.isPlatoon ? () => _addToPlatoon(top) : null,
                ),
                for (final child in top.children)
                  _ElementTile(
                    element: child,
                    depth: 1,
                    onRename: () => _rename(child),
                    onDelete: () => _delete(child),
                  ),
                const Divider(height: 1),
              ],
            ],
          );
        },
      ),
    );
  }
}

enum _Action { add, rename, delete }

class _ElementTile extends StatelessWidget {
  final OrgElement element;
  final int depth;
  final VoidCallback onRename;
  final VoidCallback? onDelete;
  final VoidCallback? onAdd;

  const _ElementTile({
    required this.element,
    required this.depth,
    required this.onRename,
    this.onDelete,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final count = element.headcount;
    return ListTile(
      contentPadding: EdgeInsets.only(left: 16.0 + depth * 24, right: 8),
      leading: Icon(switch (element.kind) {
        'company_hq' => Icons.flag,
        'platoon' => Icons.groups,
        _ => Icons.subdirectory_arrow_right,
      }),
      title: Text(element.name),
      subtitle: Text(count == 1 ? '1 soldier' : '$count soldiers'),
      trailing: PopupMenuButton<_Action>(
        onSelected: (action) => switch (action) {
          _Action.add => onAdd?.call(),
          _Action.rename => onRename(),
          _Action.delete => onDelete?.call(),
        },
        itemBuilder: (_) => [
          if (onAdd != null)
            const PopupMenuItem(
              value: _Action.add,
              child: Text('Add squad / section'),
            ),
          const PopupMenuItem(value: _Action.rename, child: Text('Rename')),
          if (onDelete != null)
            const PopupMenuItem(value: _Action.delete, child: Text('Delete')),
        ],
      ),
    );
  }
}

/// Returns the entered name via Navigator.pop.
class _NameDialog extends StatefulWidget {
  final String title;
  final String? initialName;
  final String? hint;
  final String? note;

  const _NameDialog({
    required this.title,
    this.initialName,
    this.hint,
    this.note,
  });

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _name.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: widget.hint,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
              onFieldSubmitted: (_) => _save(),
            ),
            if (widget.note != null) ...[
              const SizedBox(height: 12),
              Text(widget.note!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

/// Returns (name, kind) via Navigator.pop.
class _AddSubElementDialog extends StatefulWidget {
  final String platoonName;

  const _AddSubElementDialog({required this.platoonName});

  @override
  State<_AddSubElementDialog> createState() => _AddSubElementDialogState();
}

class _AddSubElementDialogState extends State<_AddSubElementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _kind = 'rifle_squad';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add to ${widget.platoonName}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _kind,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                for (final entry in _subElementKinds.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (value) => setState(() => _kind = value!),
            ),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: '4th Squad',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
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
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, (_name.text.trim(), _kind));
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
