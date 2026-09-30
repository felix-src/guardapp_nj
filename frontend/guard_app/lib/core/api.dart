import 'dart:convert';
import 'package:http/http.dart' as http;
import 'authed_http.dart';
import 'config.dart';
import 'token_storage.dart';

class RegisterResult {
  final String unitName;
  RegisterResult(this.unitName);
}

class RegisterException implements Exception {
  final String message;
  RegisterException(this.message);

  @override
  String toString() => message;
}

class AuthApi {
  /// Signs in and stores the token. Returns null on success, otherwise a
  /// message for the user (the server's, which covers lockouts).
  static Future<String?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final token = jsonDecode(response.body)['access_token'];
      if (token is! String || token.isEmpty) return 'Sign-in failed';
      await TokenStorage.save(token);
      return null;
    }

    if (response.statusCode == 429) {
      return 'Too many attempts. Wait a minute and try again.';
    }
    return errorMessage(response) ?? 'Invalid email or password';
  }

  /// Signs this account out on every device, including this one.
  static Future<void> logoutAllDevices() async {
    decodeOrThrow(await authedPost('/auth/logout-all'), 204);
    await endSession();
  }

  /// Changes the password; every other device is signed out and this one
  /// gets a fresh token.
  static Future<void> changePassword(String current, String next) async {
    final body = decodeOrThrow(
      await authedPost(
        '/auth/change-password',
        body: {'currentPassword': current, 'newPassword': next},
      ),
      200,
    );
    await TokenStorage.save(body['access_token'] as String);
  }

  /// Creates a soldier account in the unit that [unitCode] belongs to.
  /// Throws [RegisterException] with a message fit to show the user.
  static Future<RegisterResult> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String rank,
    required String unitCode,
    required int orgElementId,
    required String dutyRole,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'rank': rank,
        'unitCode': unitCode,
        'orgElementId': orgElementId,
        'dutyRole': dutyRole,
      }),
    );

    if (response.statusCode == 201) {
      return RegisterResult(jsonDecode(response.body)['unitName']);
    }

    if (response.statusCode == 429) {
      throw RegisterException(
        'Too many attempts. Wait a minute and try again.',
      );
    }

    throw RegisterException(
      errorMessage(response) ?? 'Sign-up failed. Please try again.',
    );
  }
}
