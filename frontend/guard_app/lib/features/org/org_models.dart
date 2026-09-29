class DutyRoleOption {
  final String key;
  final String label;

  DutyRoleOption({required this.key, required this.label});

  factory DutyRoleOption.fromJson(Map<String, dynamic> json) =>
      DutyRoleOption(key: json['key'], label: json['label']);
}

class OrgMember {
  final int id;
  final String? rank;
  final String? firstName;
  final String? lastName;
  final String? dutyRole;
  final String? dutyRoleLabel;

  /// Sent instead of [firstName] to viewers below squad leader.
  final String? firstInitial;

  OrgMember({
    required this.id,
    this.rank,
    this.firstName,
    this.lastName,
    this.dutyRole,
    this.dutyRoleLabel,
    this.firstInitial,
  });

  factory OrgMember.fromJson(Map<String, dynamic> json) {
    return OrgMember(
      id: json['id'],
      rank: json['rank'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      dutyRole: json['dutyRole'],
      dutyRoleLabel: json['dutyRoleLabel'],
      firstInitial: json['firstInitial'],
    );
  }

  /// "SGT Pat Soldier", or "SGT Soldier, P." when only the initial is shared.
  String get displayName {
    final initial = firstInitial;
    if (firstName == null && initial != null && lastName != null) {
      return [rank, '$lastName, $initial.'].whereType<String>().join(' ');
    }
    final name = [
      rank,
      firstName,
      lastName,
    ].where((part) => part != null && part.isNotEmpty).join(' ');
    return name.isEmpty ? 'Member #$id' : name;
  }
}

/// Company HQ, platoon, platoon HQ, or squad. Platoons only group other
/// elements; every other kind holds members.
class OrgElement {
  final int id;
  final String name;
  final String kind;
  final List<DutyRoleOption> roles;
  final List<OrgElement> children;

  /// Only present in the org chart, not the sign-up structure.
  final List<OrgMember> members;

  OrgElement({
    required this.id,
    required this.name,
    required this.kind,
    this.roles = const [],
    this.children = const [],
    this.members = const [],
  });

  factory OrgElement.fromJson(Map<String, dynamic> json) {
    return OrgElement(
      id: json['id'],
      name: json['name'],
      kind: json['kind'],
      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((r) => DutyRoleOption.fromJson(r as Map<String, dynamic>))
          .toList(),
      children: parseOrgElements(json['children']),
      members: (json['members'] as List<dynamic>? ?? [])
          .map((m) => OrgMember.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isPlatoon => kind == 'platoon';
  bool get isCompanyHq => kind == 'company_hq';

  /// Members here plus, for a platoon, everyone in its HQ and squads.
  int get headcount =>
      members.length + children.fold(0, (sum, c) => sum + c.headcount);
}

List<OrgElement> parseOrgElements(dynamic json) =>
    (json as List<dynamic>? ?? [])
        .map((e) => OrgElement.fromJson(e as Map<String, dynamic>))
        .toList();

/// Finds the element with [id] anywhere in [elements].
OrgElement? findOrgElement(List<OrgElement> elements, int id) {
  for (final element in elements) {
    if (element.id == id) return element;
    final found = findOrgElement(element.children, id);
    if (found != null) return found;
  }
  return null;
}

class OrgChart {
  final List<OrgElement> structure;
  final List<OrgMember> unassigned;

  /// false: the server sent only Company HQ and the viewer's platoon.
  final bool companyWide;

  OrgChart({
    required this.structure,
    required this.unassigned,
    this.companyWide = true,
  });

  factory OrgChart.fromJson(Map<String, dynamic> json) {
    return OrgChart(
      companyWide: json['access']?['companyWide'] ?? true,
      structure: parseOrgElements(json['structure']),
      unassigned: (json['unassigned'] as List<dynamic>? ?? [])
          .map((m) => OrgMember.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// What a valid unit code unlocks on the sign-up form.
class JoinInfo {
  final String unitName;
  final List<OrgElement> structure;

  JoinInfo({required this.unitName, required this.structure});

  factory JoinInfo.fromJson(Map<String, dynamic> json) => JoinInfo(
    unitName: json['unitName'],
    structure: parseOrgElements(json['structure']),
  );
}
