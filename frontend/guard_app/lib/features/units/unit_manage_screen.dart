import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';

import '../org/org_chart_screen.dart';
import 'unit.dart';
import 'unit_api.dart';
import 'unit_manage_api.dart';

enum _MemberAction { signOut, remove }

/// Readiness NCO (own unit) or admin: share the sign-up link, manage members
/// and points of contact.
class UnitManageScreen extends StatefulWidget {
  final int unitId;

  const UnitManageScreen({super.key, required this.unitId});

  @override
  State<UnitManageScreen> createState() => _UnitManageScreenState();
}

class _UnitManageData {
  final Unit unit;
  final JoinCode joinCode;
  final List<UnitMember> members;

  _UnitManageData(this.unit, this.joinCode, this.members);
}

class _UnitManageScreenState extends State<UnitManageScreen> {
  late Future<_UnitManageData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_UnitManageData> _load() async {
    final results = await Future.wait([
      UnitApi.fetchUnit(widget.unitId),
      UnitManageApi.fetchJoinCode(widget.unitId),
      UnitManageApi.fetchMembers(widget.unitId),
    ]);
    return _UnitManageData(
      results[0] as Unit,
      results[1] as JoinCode,
      results[2] as List<UnitMember>,
    );
  }

  Future<void> _refresh() async {
    final data = _load();
    setState(() => _data = data);
    await data;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _copy(String text, String what) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _showMessage('$what copied');
  }

  Future<void> _rotateCode() async {
    final ok = await _confirm(
      'Replace unit code?',
      'The current code and link will stop working immediately. Anyone who '
          "hasn't signed up yet will need the new link.",
      'Replace',
    );
    if (!ok) return;
    await _run(
      () => UnitManageApi.rotateJoinCode(widget.unitId),
      'New code created',
    );
  }

  Future<void> _removeMember(UnitMember member) async {
    final ok = await _confirm(
      'Remove ${member.displayName}?',
      'This deletes their account. They would need a current unit code to '
          'sign up again.',
      'Remove',
    );
    if (!ok) return;
    await _run(
      () => UnitManageApi.removeMember(widget.unitId, member.id),
      'Member removed',
    );
  }

  /// Lost or stolen phone: ends every session for this member.
  Future<void> _signOutMember(UnitMember member) async {
    final ok = await _confirm(
      'Sign out ${member.displayName}?',
      'Use this if their phone is lost or stolen. They will be signed out '
          'on every device and need to sign in again.',
      'Sign out',
    );
    if (!ok) return;
    await _run(
      () => UnitManageApi.revokeMemberSessions(widget.unitId, member.id),
      '${member.displayName} signed out on all devices',
    );
  }

  Future<void> _removeContact(PointOfContact contact) async {
    final ok = await _confirm(
      'Delete ${contact.name}?',
      'They will no longer be listed as a point of contact.',
      'Delete',
    );
    if (!ok) return;
    await _run(
      () => UnitManageApi.removeContact(widget.unitId, contact.id),
      'Contact deleted',
    );
  }

  Future<void> _addContact() async {
    final contact = await showDialog<_NewContact>(
      context: context,
      builder: (_) => const _AddContactDialog(),
    );
    if (contact == null) return;
    await _run(
      () => UnitManageApi.addContact(
        widget.unitId,
        name: contact.name,
        position: contact.position,
        phone: contact.phone,
        email: contact.email,
      ),
      'Contact added',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_UnitManageData>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(data?.unit.name ?? 'Manage unit'),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_tree),
                tooltip: 'Org chart',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrgChartScreen(
                      unitId: widget.unitId,
                      unitName: data?.unit.name,
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: data == null
              ? null
              : FloatingActionButton.extended(
                  onPressed: _addContact,
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('Add contact'),
                ),
          body: _body(snapshot),
        );
      },
    );
  }

  Widget _body(AsyncSnapshot<_UnitManageData> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Failed to load unit'),
            TextButton(onPressed: _refresh, child: const Text('Retry')),
          ],
        ),
      );
    }

    final data = snapshot.data!;
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          _JoinCodeCard(
            joinCode: data.joinCode,
            onCopyLink: () => _copy(data.joinCode.joinUrl, 'Sign-up link'),
            onCopyCode: () => _copy(data.joinCode.code, 'Unit code'),
            onRotate: _rotateCode,
          ),
          _SectionHeader('Members (${data.members.length})'),
          if (data.members.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('No one has signed up yet'),
            ),
          for (final member in data.members)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(member.displayName),
              subtitle: Text(
                member.isSoldier
                    ? member.email
                    : '${member.email} · ${_roleLabel(member.role)}',
              ),
              trailing: PopupMenuButton<_MemberAction>(
                tooltip: 'Member actions',
                onSelected: (action) => switch (action) {
                  _MemberAction.signOut => _signOutMember(member),
                  _MemberAction.remove => _removeMember(member),
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: _MemberAction.signOut,
                    child: Text('Sign out all devices'),
                  ),
                  if (member.isSoldier)
                    const PopupMenuItem(
                      value: _MemberAction.remove,
                      child: Text('Remove from unit'),
                    ),
                ],
              ),
            ),
          _SectionHeader('Points of contact (${data.unit.contacts.length})'),
          if (data.unit.contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'No points of contact listed',
                style: textTheme.bodyMedium,
              ),
            ),
          for (final contact in data.unit.contacts)
            ListTile(
              leading: const Icon(Icons.contact_phone_outlined),
              title: Text(contact.name),
              subtitle: Text(contact.position),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
                onPressed: () => _removeContact(contact),
              ),
            ),
        ],
      ),
    );
  }

  static String _roleLabel(String role) => switch (role) {
    'readiness_nco' => 'Readiness NCO',
    'admin' => 'Admin',
    _ => role,
  };
}

class _SectionHeader extends StatelessWidget {
  final String text;

  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _JoinCodeCard extends StatelessWidget {
  final JoinCode joinCode;
  final VoidCallback onCopyLink;
  final VoidCallback onCopyCode;
  final VoidCallback onRotate;

  const _JoinCodeCard({
    required this.joinCode,
    required this.onCopyLink,
    required this.onCopyCode,
    required this.onRotate,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Unit sign-up code', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText(
              joinCode.code,
              style: textTheme.headlineMedium?.copyWith(
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Changes automatically on ${formatDate(joinCode.expiresAt)}',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onCopyLink,
                  icon: const Icon(Icons.link),
                  label: const Text('Copy sign-up link'),
                ),
                OutlinedButton.icon(
                  onPressed: onCopyCode,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy code'),
                ),
                TextButton.icon(
                  onPressed: onRotate,
                  icon: const Icon(Icons.refresh),
                  label: const Text('New code'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NewContact {
  final String name;
  final String position;
  final String? phone;
  final String? email;

  _NewContact(this.name, this.position, this.phone, this.email);
}

class _AddContactDialog extends StatefulWidget {
  const _AddContactDialog();

  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _position = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _position, _phone, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _optional(TextEditingController c) {
    final value = c.text.trim();
    return value.isEmpty ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add point of contact'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'SSG Jane Doe',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _position,
                decoration: const InputDecoration(
                  labelText: 'Duty position',
                  hintText: 'Readiness NCO',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(
                  labelText: 'Duty phone (optional)',
                ),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(
                  labelText: 'Official email (optional)',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
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
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _NewContact(
                _name.text.trim(),
                _position.text.trim(),
                _optional(_phone),
                _optional(_email),
              ),
            );
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
