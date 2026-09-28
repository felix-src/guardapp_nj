import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:guard_app/features/units/unit.dart';
import 'package:guard_app/features/units/unit_manage_api.dart';

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

  test('JoinCode.fromJson parses GET /units/:id/join-code', () {
    final code = JoinCode.fromJson(
      jsonDecode(
        '{"code":"5AS2-6KNP","expiresAt":"2026-10-05T03:49:35.305Z",'
        '"joinUrl":"http://localhost:8080/join?code=5AS2-6KNP"}',
      ),
    );

    expect(code.code, '5AS2-6KNP');
    expect(code.expiresAt.toUtc(), DateTime.utc(2026, 10, 5, 3, 49, 35, 305));
    expect(code.joinUrl, endsWith('?code=5AS2-6KNP'));
  });

  test('UnitMember.displayName falls back to email when unnamed', () {
    final named = UnitMember.fromJson(
      jsonDecode(
        '{"id":6,"email":"pat@example.com","role":"soldier",'
        '"firstName":"Pat","lastName":"Soldier","rank":"SPC"}',
      ),
    );
    final unnamed = UnitMember.fromJson(
      jsonDecode(
        '{"id":1,"email":"admin@example.com","role":"admin",'
        '"firstName":null,"lastName":null,"rank":null}',
      ),
    );

    expect(named.displayName, 'SPC Pat Soldier');
    expect(named.isSoldier, isTrue);
    expect(unnamed.displayName, 'admin@example.com');
    expect(unnamed.isSoldier, isFalse);
  });

  test('Unit.fromJson parses GET /units list items without contacts', () {
    final unit = Unit.fromJson(
      jsonDecode('{"id":3,"name":"50th IBCT","state":"NJ"}'),
    );

    expect(unit.id, 3);
    expect(unit.contacts, isEmpty);
  });
}
