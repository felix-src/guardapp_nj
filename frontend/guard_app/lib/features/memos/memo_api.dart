import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/config.dart';
import '../../core/token_storage.dart';

class MemoApi {
  static Future<List<dynamic>> fetchMemos() async {
    final token = await TokenStorage.read();

    if (token == null) {
      throw Exception('No auth token found');
    }

    final response = await http.get(
      Uri.parse('$apiBaseUrl/memos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load memos (status ${response.statusCode})');
  }
}
