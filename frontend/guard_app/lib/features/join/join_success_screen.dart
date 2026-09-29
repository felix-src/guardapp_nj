import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ui.dart';

// Store listings, once published:
//   flutter build web --dart-define=IOS_APP_URL=... --dart-define=ANDROID_APP_URL=...
const _iosAppUrl = String.fromEnvironment('IOS_APP_URL');
const _androidAppUrl = String.fromEnvironment('ANDROID_APP_URL');

/// Shown after sign-up. On the web it points people to the app; in the app
/// it sends them to log in.
class JoinSuccessScreen extends StatelessWidget {
  final String unitName;

  const JoinSuccessScreen({super.key, required this.unitName});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BrandedFormScaffold(
      title: 'Welcome aboard',
      subtitle: "You've joined $unitName",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.check_circle, color: colors.primary, size: 56),
          const SizedBox(height: 16),
          if (kIsWeb) ..._getTheApp(textTheme) else _logIn(context),
        ],
      ),
    );
  }

  List<Widget> _getTheApp(TextTheme textTheme) {
    if (_iosAppUrl.isEmpty && _androidAppUrl.isEmpty) {
      return [
        Text(
          "The Guard Resource App isn't in the App Store yet. Your Readiness "
          'NCO will let you know when you can download it, and you can log '
          'in with the email and password you just created.',
          style: textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ];
    }

    return [
      Text(
        'Download the app and log in with the email and password you just '
        'created.',
        style: textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),
      if (_iosAppUrl.isNotEmpty)
        ElevatedButton.icon(
          icon: const Icon(Icons.phone_iphone),
          label: const Text('Download on the App Store'),
          onPressed: () => launchUrl(Uri.parse(_iosAppUrl)),
        ),
      if (_iosAppUrl.isNotEmpty && _androidAppUrl.isNotEmpty)
        const SizedBox(height: 12),
      if (_androidAppUrl.isNotEmpty)
        OutlinedButton.icon(
          icon: const Icon(Icons.android),
          label: const Text('Get it on Google Play'),
          onPressed: () => launchUrl(Uri.parse(_androidAppUrl)),
        ),
    ];
  }

  Widget _logIn(BuildContext context) {
    return ElevatedButton(
      onPressed: () =>
          Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
      child: const Text('Log in'),
    );
  }
}
