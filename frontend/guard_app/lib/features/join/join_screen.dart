import 'package:flutter/material.dart';

import '../../core/api.dart';
import 'join_success_screen.dart';
import 'ranks.dart';

/// Sign-up with a unit code. Reached from the Readiness NCO's link
/// (/join?code=...) on the web, or from the login screen in the app.
class JoinScreen extends StatefulWidget {
  final String? initialCode;

  const JoinScreen({super.key, this.initialCode});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.initialCode ?? '');
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _rank;
  bool _submitting = false;
  String? _error;

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join your unit')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Use the unit code from your Readiness NCO. It changes '
                  'every week, so ask for a new link if yours has expired.',
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
                ),
                const SizedBox(height: 16),
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
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                  ),
                  obscureText: true,
                  validator: (value) =>
                      value != _password.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                ],
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
