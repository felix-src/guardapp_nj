import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app.dart';
import 'core/token_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Web links look like /join?code=... instead of /#/join?code=...
  usePathUrlStrategy();
  final token = await TokenStorage.read();
  runApp(GuardApp(isAuthenticated: token != null));
}
