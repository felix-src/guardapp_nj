import 'dart:convert';

import 'authed_http.dart';

class CurrentUser {
  final int id;
  final String email;
  final String role;
  final int? unitId;

  CurrentUser({
    required this.id,
    required this.email,
    required this.role,
    this.unitId,
  });

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      id: json['id'],
      email: json['email'],
      role: json['role'],
      unitId: json['unitId'],
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isReadinessNco => role == 'readiness_nco';

  /// Mirrors the server's UnitScopeGuard; the server still enforces it.
  bool canManageUnit(int unitId) =>
      isAdmin || (isReadinessNco && this.unitId == unitId);
}

/// The logged-in user's profile, loaded from GET /auth/me.
class Session {
  static CurrentUser? user;

  static Future<CurrentUser> load() async {
    final response = await authedGet('/auth/me');
    if (response.statusCode != 200) {
      throw Exception('Failed to load profile (status ${response.statusCode})');
    }
    return user = CurrentUser.fromJson(jsonDecode(response.body));
  }

  static void clear() => user = null;
}
