import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/ui.dart';
import '../org/org_api.dart';
import '../org/org_models.dart';
import '../org/position_picker.dart';
import 'join_success_screen.dart';
import 'ranks.dart';

typedef JoinCodeLookup = Future<JoinInfo> Function(String code);

/// Sign-up with a unit code, in two steps: check the code (automatic when it
/// comes from the Readiness NCO's /join?code=... link), then enter details
/// including platoon, squad, and duty role. Also reachable from the app's
/// login screen.
class JoinScreen extends StatefulWidget {
  final String? initialCode;

  /// Replaceable in tests; defaults to the server lookup.
  final JoinCodeLookup lookupJoinCode;

  const JoinScreen({
    super.key,
    this.initialCode,
    this.lookupJoinCode = OrgApi.fetchJoinInfo,
  });

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _codeFormKey = GlobalKey<FormState>();
  final _detailsFormKey = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.initialCode ?? '');
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  JoinInfo? _joinInfo;
  Position? _position;
  String? _rank;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_code.text.trim().isNotEmpty) _checkCode();
  }

  @override
  void dispose() {
    for (final c in [
      _code,
      _firstName,
      _lastName,
      _email,
      _password,
      _confirm,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _checkCode() async {
    final code = _code.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final info = await widget.lookupJoinCode(code);
      if (!mounted) return;
      setState(() {
        _joinInfo = info;
        _position = null;
      });
    } on JoinCodeException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not check that code');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _changeCode() {
    setState(() {
      _joinInfo = null;
      _position = null;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_detailsFormKey.currentState!.validate()) return;
    final position = _position!;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final result = await AuthApi.register(
        email: _email.text.trim(),
        password: _password.text,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        rank: _rank!,
        unitCode: _code.text.trim(),
        orgElementId: position.orgElementId,
        dutyRole: position.dutyRole,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => JoinSuccessScreen(unitName: result.unitName),
        ),
      );
    } on RegisterException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not reach the server');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    final joinInfo = _joinInfo;

    return BrandedFormScaffold(
      title: 'Join your unit',
      subtitle: joinInfo == null
          ? 'Enter the code from your Readiness NCO'
          : 'Tell us where you serve',
      showBack: Navigator.canPop(context),
      child: joinInfo == null ? _codeStep() : _detailsStep(joinInfo),
    );
  }

  Widget _codeStep() {
    return Form(
      key: _codeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Use the unit code from your Readiness NCO. It changes every '
            'week, so ask for a new link if yours has expired.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _code,
            decoration: const InputDecoration(
              labelText: 'Unit code',
              hintText: 'XXXX-XXXX',
            ),
            textCapitalization: TextCapitalization.characters,
            validator: _required,
            onFieldSubmitted: (_) => _continue(),
          ),
          const SizedBox(height: 24),
          ..._errorText(),
          ElevatedButton(
            onPressed: _busy ? null : _continue,
            child: _busy ? const _Spinner() : const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _continue() {
    if (_codeFormKey.currentState!.validate()) _checkCode();
  }

  Widget _detailsStep(JoinInfo joinInfo) {
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _detailsFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            margin: EdgeInsets.zero,
            color: Theme.of(context).inputDecorationTheme.fillColor,
            child: ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: Text(joinInfo.unitName),
              subtitle: Text('Unit code ${_code.text.trim().toUpperCase()}'),
              trailing: TextButton(
                onPressed: _busy ? null : _changeCode,
                child: const Text('Change'),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Your position', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          PositionPicker(
            structure: joinInfo.structure,
            onChanged: (position) => _position = position,
          ),
          const SizedBox(height: 24),
          Text('About you', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _rank,
            decoration: const InputDecoration(labelText: 'Rank'),
            items: [
              for (final r in armyRanks)
                DropdownMenuItem(value: r, child: Text(r)),
            ],
            onChanged: (value) => setState(() => _rank = value),
            validator: (value) => value == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _firstName,
            decoration: const InputDecoration(labelText: 'First name'),
            textCapitalization: TextCapitalization.words,
            validator: _required,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lastName,
            decoration: const InputDecoration(labelText: 'Last name'),
            textCapitalization: TextCapitalization.words,
            validator: _required,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return 'Required';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _password,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: (value) => (value == null || value.length < 8)
                ? 'At least 8 characters'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirm,
            decoration: const InputDecoration(labelText: 'Confirm password'),
            obscureText: true,
            validator: (value) =>
                value != _password.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 24),
          ..._errorText(),
          ElevatedButton(
            onPressed: _busy ? null : _submit,
            child: _busy ? const _Spinner() : const Text('Create account'),
          ),
        ],
      ),
    );
  }

  List<Widget> _errorText() => [if (_error != null) ErrorText(_error!)];
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) =>
      const CupertinoActivityIndicator(color: Colors.white);
}
