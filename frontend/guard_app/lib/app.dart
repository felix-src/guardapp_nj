import 'package:flutter/material.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';

class GuardApp extends StatelessWidget {
  final bool isAuthenticated;
  const GuardApp({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guard Resource App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),

      // 🔐 THIS IS THE ONLY LOGIC CHANGE
      initialRoute: isAuthenticated ? '/home' : '/',

      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
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
