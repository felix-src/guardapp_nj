import 'package:flutter/material.dart';
import 'app.dart';
import 'core/token_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final token = await TokenStorage.read();
  runApp(GuardApp(isAuthenticated: token != null));
}
