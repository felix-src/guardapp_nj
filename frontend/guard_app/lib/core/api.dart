import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'token_storage.dart';

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
}
