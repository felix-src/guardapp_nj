import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'core/authed_http.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/join/join_screen.dart';
import 'features/units/units_screen.dart';

class GuardApp extends StatelessWidget {
  final bool isAuthenticated;
  const GuardApp({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'NJ Guard',
      debugShowCheckedModeBanner: false,
      theme: buildGuardTheme(Brightness.light),
      darkTheme: buildGuardTheme(Brightness.dark),

      // 🔐 THIS IS THE ONLY LOGIC CHANGE
      initialRoute: isAuthenticated ? '/home' : '/',

      onGenerateRoute: _route,
      // One route for the starting URL, so a /join link doesn't also stack
      // the login screen underneath it.
      onGenerateInitialRoutes: (name) => [_route(RouteSettings(name: name))],
    );
  }

  static Route<dynamic> _route(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');

    // The web build is only the sign-up site that NCO links point to;
    // soldiers use the mobile app for everything else.
    if (kIsWeb || uri.path == '/join') {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => JoinScreen(initialCode: uri.queryParameters['code']),
      );
    }

    return MaterialPageRoute(
      settings: settings,
      builder: (_) => switch (uri.path) {
        '/home' => const HomeScreen(),
        '/units' => const UnitsScreen(),
        _ => const LoginScreen(),
      },
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Guard Resource App\nFrontend Initialized',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
