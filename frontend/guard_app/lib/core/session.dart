import 'dart:convert';

import 'authed_http.dart';

class CurrentUser {
  final int id;
  final String email;
  final String role;
  final int? unitId;
  final String? unitName;
  final String? firstName;
  final String? lastName;
  final String? rank;
  final String? dutyRoleLabel;

  /// e.g. "2nd Squad, 1st Platoon"
  final String? position;

  CurrentUser({
    required this.id,
    required this.email,
    required this.role,
    this.unitId,
    this.unitName,
    this.firstName,
    this.lastName,
    this.rank,
    this.dutyRoleLabel,
    this.position,
  });

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      id: json['id'],
      email: json['email'],
      role: json['role'],
      unitId: json['unitId'],
      unitName: json['unitName'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      rank: json['rank'],
      dutyRoleLabel: json['dutyRoleLabel'],
      position: json['position'],
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isReadinessNco => role == 'readiness_nco';

  /// "SGT Pat Soldier", or the email for accounts without a name.
  String get displayName {
    final name = [
      rank,
      firstName,
      lastName,
    ].where((part) => part != null && part.isNotEmpty).join(' ');
    return name.isEmpty ? email : name;
  }

  /// "PS" for Pat Soldier; first letter of the email otherwise.
  String get initials {
    final letters = [firstName, lastName]
        .where((part) => part != null && part.isNotEmpty)
        .map((part) => part![0])
        .join();
    return (letters.isEmpty ? email[0] : letters).toUpperCase();
  }

  /// Mirrors the server's UnitMemberGuard (org chart access).
  bool canViewUnitChart(int unitId) => isAdmin || this.unitId == unitId;

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
