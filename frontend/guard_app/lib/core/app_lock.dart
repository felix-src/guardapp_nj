import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import 'theme.dart';
import 'token_storage.dart';
import 'ui.dart';

enum UnlockResult { unlocked, failed, unavailable }

/// Face ID / Touch ID / device passcode via local_auth.
Future<UnlockResult> deviceUnlock() async {
  final auth = LocalAuthentication();
  if (!await auth.isDeviceSupported()) return UnlockResult.unavailable;
  try {
    final ok = await auth.authenticate(
      localizedReason: 'Unlock NJ Guard',
      persistAcrossBackgrounding: true,
    );
    return ok ? UnlockResult.unlocked : UnlockResult.failed;
  } on LocalAuthException catch (e) {
    return switch (e.code) {
      LocalAuthExceptionCode.noCredentialsSet ||
      LocalAuthExceptionCode.noBiometricHardware => UnlockResult.unavailable,
      _ => UnlockResult.failed,
    };
  }
}

/// Protects a signed-in session on a lost or stolen phone:
/// - requires Face ID / passcode when the app starts with a saved session
///   and when it returns after [relockAfter] in the background;
/// - covers the screen whenever the app isn't in front, so the iOS app
///   switcher snapshot never shows unit information.
/// A phone with no passcode can't be protected, so the app won't open.
class AppLock extends StatefulWidget {
  final Widget child;
  final bool lockOnStart;
  final Duration relockAfter;

  /// Replaceable in tests; defaults to [deviceUnlock].
  final Future<UnlockResult> Function() unlock;

  /// Whether a session exists; replaceable in tests.
  final Future<bool> Function() isSignedIn;

  /// Called when the user chooses to sign out from the lock screen.
  final VoidCallback onSignOut;

  const AppLock({
    super.key,
    required this.child,
    required this.lockOnStart,
    required this.onSignOut,
    this.relockAfter = const Duration(seconds: 30),
    this.unlock = deviceUnlock,
    this.isSignedIn = _hasToken,
  });

  static Future<bool> _hasToken() async => await TokenStorage.read() != null;

  @override
  State<AppLock> createState() => _AppLockState();
}

class _AppLockState extends State<AppLock> with WidgetsBindingObserver {
  late bool _locked = widget.lockOnStart;
  bool _covered = false;
  bool _unlocking = false;
  bool _unavailable = false;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_locked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        // Also fires while the Face ID prompt is up; only cover, don't lock
        setState(() => _covered = true);
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _backgroundedAt ??= DateTime.now();
        setState(() => _covered = true);
      case AppLifecycleState.resumed:
        _onResumed();
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _onResumed() async {
    final since = _backgroundedAt;
    _backgroundedAt = null;
    final relock =
        since != null &&
        DateTime.now().difference(since) >= widget.relockAfter &&
        await widget.isSignedIn();
    if (!mounted) return;
    setState(() {
      _covered = false;
      if (relock) _locked = true;
    });
    if (relock) _unlock();
  }

  Future<void> _unlock() async {
    if (_unlocking) return;
    setState(() => _unlocking = true);
    final result = await widget.unlock();
    if (!mounted) return;
    setState(() {
      _unlocking = false;
      _unavailable = result == UnlockResult.unavailable;
      if (result == UnlockResult.unlocked) _locked = false;
    });
  }

  void _signOut() {
    setState(() {
      _locked = false;
      _unavailable = false;
    });
    widget.onSignOut();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_locked || _covered)
          _LockCover(
            locked: _locked,
            unlocking: _unlocking,
            unavailable: _unavailable,
            onUnlock: _unlock,
            onSignOut: _signOut,
          ),
      ],
    );
  }
}

class _LockCover extends StatelessWidget {
  final bool locked;
  final bool unlocking;
  final bool unavailable;
  final VoidCallback onUnlock;
  final VoidCallback onSignOut;

  const _LockCover({
    required this.locked,
    required this.unlocking,
    required this.unavailable,
    required this.onUnlock,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final soft = Colors.white.withValues(alpha: 0.85);

    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(gradient: GuardColors.heroGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(),
                  if (locked) ...[
                    const SizedBox(height: 32),
                    Icon(
                      unavailable ? Icons.no_encryption : Icons.lock,
                      color: Colors.white,
                      size: 36,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      unavailable
                          ? 'Set a device passcode'
                          : 'NJ Guard is locked',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      unavailable
                          ? 'NJ Guard requires a passcode, Face ID, or Touch ID '
                                'on this phone to protect unit information if '
                                "it's lost. Turn one on in Settings, then try "
                                'again.'
                          : 'Use Face ID, Touch ID, or your passcode to continue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: soft, height: 1.35),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: 240,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: GuardColors.tan,
                          foregroundColor: GuardColors.ink,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: unlocking ? null : onUnlock,
                        child: unlocking
                            ? const CupertinoActivityIndicator()
                            : Text(unavailable ? 'Try again' : 'Unlock'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: soft),
                      onPressed: unlocking ? null : onSignOut,
                      child: const Text('Sign out'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
