import 'package:flutter/material.dart';
import '../../core/token_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _enforceAuth();
  }

  Future<void> _enforceAuth() async {
    final token = await TokenStorage.read();
    if (token == null && mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Future<void> _logout() async {
    await TokenStorage.clear();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome to the Guard Resource App',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
