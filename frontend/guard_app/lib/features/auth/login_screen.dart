import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/api.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? error;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    bool success = false;
    String? failure;
    try {
      success = await AuthApi.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      if (!success) failure = 'Invalid credentials';
    } catch (_) {
      failure = 'Could not reach the server';
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
      error = failure;
    });

    if (success) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BrandedFormScaffold(
      title: 'Guard Resource App',
      subtitle: 'Sign in to your unit',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => isLoading ? null : handleLogin(),
          ),
          const SizedBox(height: 20),
          if (error != null) ErrorText(error!),
          ElevatedButton(
            onPressed: isLoading ? null : handleLogin,
            child: isLoading
                ? const CupertinoActivityIndicator(color: Colors.white)
                : const Text('Login'),
          ),
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: GuardColors.saddle),
            onPressed: () => Navigator.pushNamed(context, '/join'),
            child: const Text('New here? Join with a unit code'),
          ),
        ],
      ),
    );
  }
}
