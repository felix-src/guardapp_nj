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
  static String? accessToken;

  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);

      final token = data['access_token'];
      if (token == null || token.isEmpty) {
        return false;
      }

      accessToken = token;
      await TokenStorage.save(token);
      return true;
    }

    return false;
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
