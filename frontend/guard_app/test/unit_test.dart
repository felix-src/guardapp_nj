import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:guard_app/features/units/unit.dart';

void main() {
  test('Unit.fromJson parses GET /units/:id with contacts', () {
    final unit = Unit.fromJson(
      jsonDecode('''
      {"id":1,"name":"1-114th Infantry","state":"NJ","contacts":[
        {"id":2,"name":"CPT John Roe","position":"Commander","phone":null,"email":null,"unitId":1},
        {"id":1,"name":"SSG Jane Doe","position":"Readiness NCO","phone":"609-555-0100","email":"jane.doe@army.mil","unitId":1}
      ]}
      '''),
    );

    expect(unit.name, '1-114th Infantry');
    expect(unit.contacts, hasLength(2));
    expect(unit.contacts[0].phone, isNull);
    expect(unit.contacts[0].email, isNull);
    expect(unit.contacts[1].position, 'Readiness NCO');
    expect(unit.contacts[1].email, 'jane.doe@army.mil');
  });

  test('Unit.fromJson parses GET /units list items without contacts', () {
    final unit = Unit.fromJson(
      jsonDecode('{"id":3,"name":"50th IBCT","state":"NJ"}'),
    );

    expect(unit.id, 3);
    expect(unit.contacts, isEmpty);
  });
}
