import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guard_app/core/app_lock.dart';

const secret = 'Unit roster';

Future<void> pumpLock(
  WidgetTester tester, {
  required bool lockOnStart,
  required Future<UnlockResult> Function() unlock,
  Duration relockAfter = const Duration(seconds: 30),
  VoidCallback? onSignOut,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: AppLock(
        lockOnStart: lockOnStart,
        unlock: unlock,
        relockAfter: relockAfter,
        isSignedIn: () async => true,
        onSignOut: onSignOut ?? () {},
        child: const Scaffold(body: Text(secret)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void setLifecycle(WidgetTester tester, AppLifecycleState state) {
  tester.binding.handleAppLifecycleStateChanged(state);
}

void main() {
  testWidgets('a saved session starts locked and unlocks', (tester) async {
    var attempts = 0;
    var result = UnlockResult.failed;
    await pumpLock(
      tester,
      lockOnStart: true,
      unlock: () async {
        attempts++;
        return result;
      },
    );

    // Prompted automatically; the failed attempt leaves it locked
    expect(attempts, 1);
    expect(find.text('NJ Guard is locked'), findsOneWidget);

    result = UnlockResult.unlocked;
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(find.text('NJ Guard is locked'), findsNothing);
    expect(find.text(secret), findsOneWidget);
  });

  testWidgets('a phone without a passcode cannot open the app', (tester) async {
    var signedOut = false;
    await pumpLock(
      tester,
      lockOnStart: true,
      unlock: () async => UnlockResult.unavailable,
      onSignOut: () => signedOut = true,
    );

    expect(find.text('Set a device passcode'), findsOneWidget);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(signedOut, isTrue);
  });

  testWidgets('no lock without a saved session', (tester) async {
    var attempts = 0;
    await pumpLock(
      tester,
      lockOnStart: false,
      unlock: () async {
        attempts++;
        return UnlockResult.unlocked;
      },
    );
    expect(attempts, 0);
    expect(find.text('NJ Guard is locked'), findsNothing);
  });

  testWidgets('covers the screen in the app switcher', (tester) async {
    await pumpLock(
      tester,
      lockOnStart: false,
      unlock: () async => UnlockResult.unlocked,
    );

    setLifecycle(tester, AppLifecycleState.inactive);
    await tester.pump();
    // The cover sits on top; the brand shows, the lock prompt doesn't
    expect(find.text('NEW JERSEY NATIONAL GUARD'), findsOneWidget);
    expect(find.text('NJ Guard is locked'), findsNothing);

    setLifecycle(tester, AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('NEW JERSEY NATIONAL GUARD'), findsNothing);
  });

  testWidgets('relocks after time in the background, not after a quick '
      'switch', (tester) async {
    var attempts = 0;
    await pumpLock(
      tester,
      lockOnStart: false,
      // Zero: any trip to the background counts as long enough
      relockAfter: Duration.zero,
      unlock: () async {
        attempts++;
        return UnlockResult.failed;
      },
    );

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      setLifecycle(tester, state);
    }
    await tester.pump();
    setLifecycle(tester, AppLifecycleState.hidden);
    setLifecycle(tester, AppLifecycleState.inactive);
    setLifecycle(tester, AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(attempts, 1);
    expect(find.text('NJ Guard is locked'), findsOneWidget);
  });

  testWidgets('a quick switch does not relock', (tester) async {
    var attempts = 0;
    await pumpLock(
      tester,
      lockOnStart: false,
      relockAfter: const Duration(hours: 1),
      unlock: () async {
        attempts++;
        return UnlockResult.unlocked;
      },
    );

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      setLifecycle(tester, state);
    }
    await tester.pumpAndSettle();

    expect(attempts, 0);
    expect(find.text(secret), findsOneWidget);
    expect(find.text('NJ Guard is locked'), findsNothing);
  });
}
