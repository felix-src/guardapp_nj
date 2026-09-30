import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'session.dart';
import 'token_storage.dart';

/// Lets API code send the user back to login without a BuildContext.
final navigatorKey = GlobalKey<NavigatorState>();

class SessionExpiredException implements Exception {
  @override
  String toString() => 'Session expired';
}

/// GET [path] with the stored JWT. A missing or rejected token (401) clears
/// the session and returns to the login screen.
Future<http.Response> authedGet(String path) => _send('GET', path);

/// POST [path] with an optional JSON [body]. Same 401 handling as [authedGet].
Future<http.Response> authedPost(String path, {Object? body}) =>
    _send('POST', path, body: body);

/// PATCH [path] with an optional JSON [body]. Same 401 handling as [authedGet].
Future<http.Response> authedPatch(String path, {Object? body}) =>
    _send('PATCH', path, body: body);

/// DELETE [path]. Same 401 handling as [authedGet].
Future<http.Response> authedDelete(String path) => _send('DELETE', path);

Future<http.Response> _send(String method, String path, {Object? body}) async {
  final token = await TokenStorage.read();
  if (token == null) {
    await endSession();
    throw SessionExpiredException();
  }

  final request = http.Request(method, Uri.parse('$apiBaseUrl$path'))
    ..headers['Authorization'] = 'Bearer $token';
  if (body != null) {
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(body);
  }

  final response = await http.Response.fromStream(await request.send());

  if (response.statusCode == 401) {
    await endSession();
    throw SessionExpiredException();
  }

  return response;
}

/// Decoded JSON body (null if empty) when [response] has [expectedStatus];
/// otherwise throws with the server's error message.
dynamic decodeOrThrow(http.Response response, int expectedStatus) {
  if (response.statusCode != expectedStatus) {
    throw Exception(
      errorMessage(response) ??
          'Request failed (status ${response.statusCode})',
    );
  }
  return response.body.isEmpty ? null : jsonDecode(response.body);
}

/// The server's error message from a Nest error response, if there is one.
String? errorMessage(http.Response response) {
  try {
    final message = jsonDecode(response.body)['message'];
    if (message is List) return message.join('\n');
    if (message is String) return message;
  } catch (_) {}
  return null;
}

/// Clears the local session and returns to the login screen.
Future<void> endSession() async {
  await TokenStorage.clear();
  Session.clear();
  navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (_) => false);
}
