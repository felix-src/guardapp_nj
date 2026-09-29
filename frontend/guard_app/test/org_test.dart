import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:guard_app/features/org/org_models.dart';

void main() {
  // Same shape as GET /units/:id/org-chart
  final chart = OrgChart.fromJson(
    jsonDecode('''
{"structure":[
  {"id":1,"name":"Company HQ","kind":"company_hq","children":[],"roles":[],
   "members":[{"id":12,"rank":"SSG","firstName":"Sam","lastName":"Nco",
     "dutyRole":"readiness_nco","dutyRoleLabel":"Readiness NCO"}]},
  {"id":2,"name":"1st Platoon","kind":"platoon","roles":[],"children":[
    {"id":3,"name":"Platoon HQ","kind":"platoon_hq","children":[],"roles":[],
     "members":[]},
    {"id":4,"name":"2nd Squad","kind":"rifle_squad","children":[],"roles":[],
     "members":[
       {"id":11,"rank":"SGT","firstName":"Pat","lastName":"Soldier",
        "dutyRole":"team_leader","dutyRoleLabel":"Team Leader"},
       {"id":13,"rank":"PFC","firstName":"Lee","lastName":"Park",
        "dutyRole":"rifleman","dutyRoleLabel":"Rifleman"}]}]}
],
"unassigned":[{"id":9,"rank":null,"firstName":null,"lastName":null,
  "dutyRole":null,"dutyRoleLabel":null}]}
'''),
  );

  test('parses the org chart tree and unassigned members', () {
    expect(chart.structure, hasLength(2));
    expect(chart.structure[0].isCompanyHq, isTrue);
    expect(chart.structure[1].isPlatoon, isTrue);
    expect(
      chart.structure[1].children[1].members[0].displayName,
      'SGT Pat Soldier',
    );
    expect(chart.unassigned.single.displayName, 'Member #9');
  });

  test('headcount includes a platoon\'s HQ and squads', () {
    expect(chart.structure[0].headcount, 1);
    expect(chart.structure[1].headcount, 2);
    expect(chart.structure[1].children[0].headcount, 0);
  });

  test('findOrgElement searches nested elements', () {
    expect(findOrgElement(chart.structure, 4)?.name, '2nd Squad');
    expect(findOrgElement(chart.structure, 1)?.name, 'Company HQ');
    expect(findOrgElement(chart.structure, 99), isNull);
  });

  test('restricted charts show rank, last name, and first initial', () {
    final restricted = OrgChart.fromJson(
      jsonDecode('''
{"access":{"companyWide":false,"fullNames":false},
 "structure":[{"id":1,"name":"Company HQ","kind":"company_hq","children":[],
   "roles":[],"members":[{"id":5,"rank":"SGT","firstName":null,
   "firstInitial":"F","lastName":"Lopez","dutyRole":"rto",
   "dutyRoleLabel":"RTO"}]}],
 "unassigned":[]}
'''),
    );

    expect(restricted.companyWide, isFalse);
    expect(
      restricted.structure.single.members.single.displayName,
      'SGT Lopez, F.',
    );
    // Charts without an access block (older servers) count as full
    expect(chart.companyWide, isTrue);
  });
}
