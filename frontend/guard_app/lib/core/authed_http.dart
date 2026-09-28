import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'token_storage.dart';

/// Lets API code send the user back to login without a BuildContext.
final navigatorKey = GlobalKey<NavigatorState>();

class SessionExpiredException implements Exception {
  @override
  String toString() => 'Session expired';
}

/// GET [path] with the stored JWT. A missing or rejected token (401) clears
/// the session and returns to the login screen.
Future<http.Response> authedGet(String path) async {
  final token = await TokenStorage.read();
  if (token == null) {
    await _endSession();
    throw SessionExpiredException();
  }

  final response = await http.get(
    Uri.parse('$apiBaseUrl$path'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 401) {
    await _endSession();
    throw SessionExpiredException();
  }

  return response;
}

Future<void> _endSession() async {
  await TokenStorage.clear();
  navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (_) => false);
}
