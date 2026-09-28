import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/authed_http.dart';

class JoinCode {
  final String code;
  final DateTime expiresAt;
  final String joinUrl;

  JoinCode({
    required this.code,
    required this.expiresAt,
    required this.joinUrl,
  });

  factory JoinCode.fromJson(Map<String, dynamic> json) {
    return JoinCode(
      code: json['code'],
      expiresAt: DateTime.parse(json['expiresAt']).toLocal(),
      joinUrl: json['joinUrl'],
    );
  }
}

class UnitMember {
  final int id;
  final String email;
  final String role;
  final String? firstName;
  final String? lastName;
  final String? rank;

  UnitMember({
    required this.id,
    required this.email,
    required this.role,
    this.firstName,
    this.lastName,
    this.rank,
  });

  factory UnitMember.fromJson(Map<String, dynamic> json) {
    return UnitMember(
      id: json['id'],
      email: json['email'],
      role: json['role'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      rank: json['rank'],
    );
  }

  /// "SPC Pat Soldier", falling back to the email for accounts with no name.
  String get displayName {
    final name = [
      rank,
      firstName,
      lastName,
    ].where((part) => part != null && part.isNotEmpty).join(' ');
    return name.isEmpty ? email : name;
  }

  bool get isSoldier => role == 'soldier';
}

/// Readiness NCO / admin calls for one unit. The server enforces who may
/// call these (UnitScopeGuard).
class UnitManageApi {
  static Future<JoinCode> fetchJoinCode(int unitId) async {
    final response = await authedGet('/units/$unitId/join-code');
    return JoinCode.fromJson(_decode(response, 200));
  }

  static Future<JoinCode> rotateJoinCode(int unitId) async {
    final response = await authedPost('/units/$unitId/join-code/rotate');
    return JoinCode.fromJson(_decode(response, 201));
  }

  static Future<List<UnitMember>> fetchMembers(int unitId) async {
    final response = await authedGet('/units/$unitId/members');
    final body = _decode(response, 200) as List<dynamic>;
    return body
        .map((m) => UnitMember.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  static Future<void> removeMember(int unitId, int userId) async {
    final response = await authedDelete('/units/$unitId/members/$userId');
    _decode(response, 204);
  }

  static Future<void> addContact(
    int unitId, {
    required String name,
    required String position,
    String? phone,
    String? email,
  }) async {
    final response = await authedPost(
      '/units/$unitId/contacts',
      body: {
        'name': name,
        'position': position,
        'phone': ?phone,
        'email': ?email,
      },
    );
    _decode(response, 201);
  }

  static Future<void> removeContact(int unitId, int contactId) async {
    final response = await authedDelete('/units/$unitId/contacts/$contactId');
    _decode(response, 204);
  }

  static dynamic _decode(http.Response response, int expectedStatus) {
    if (response.statusCode != expectedStatus) {
      throw Exception(
        errorMessage(response) ??
            'Request failed (status ${response.statusCode})',
      );
    }
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }
}
