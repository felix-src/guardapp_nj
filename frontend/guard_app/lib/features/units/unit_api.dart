import 'dart:convert';

import '../../core/authed_http.dart';
import 'unit.dart';

class UnitApi {
  static Future<List<Unit>> fetchUnits() async {
    final body = await _get('/units') as List<dynamic>;
    return body.map((u) => Unit.fromJson(u as Map<String, dynamic>)).toList();
  }

  /// Returns the unit with its points of contact.
  static Future<Unit> fetchUnit(int id) async {
    final body = await _get('/units/$id') as Map<String, dynamic>;
    return Unit.fromJson(body);
  }

  static Future<dynamic> _get(String path) async {
    final response = await authedGet(path);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Request to $path failed (status ${response.statusCode})');
  }
}
