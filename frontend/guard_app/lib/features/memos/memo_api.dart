import 'dart:convert';

import '../../core/authed_http.dart';

class MemoApi {
  static Future<List<dynamic>> fetchMemos() async {
    final response = await authedGet('/memos');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load memos (status ${response.statusCode})');
  }
}
