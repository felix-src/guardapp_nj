import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guard_app/core/session.dart';
import 'package:guard_app/features/resources/resource_models.dart';

void main() {
  test('ResourceDirectory parses GET /resources', () {
    final directory = ResourceDirectory.fromJson(
      jsonDecode('''
{"crisisLine":{"title":"Military & Veterans Crisis Line","description":"d",
  "url":"https://www.veteranscrisisline.net/","phone":"988",
  "phoneLabel":"988, then press 1"},
 "newJersey":[{"title":"Education","icon":"school","items":[
   {"title":"NJ National Guard Tuition Program","description":"d",
    "url":"https://education.njarmyguard.com/njngtp"}]}],
 "national":[{"title":"Support","icon":"unknown-key","items":[
   {"title":"Military OneSource","description":"d",
    "url":"https://www.militaryonesource.mil/","phone":"8003429647",
    "phoneLabel":"800-342-9647"}]}]}
'''),
    );

    expect(directory.crisisLine.phone, '988');
    expect(directory.newJersey.single.iconData, Icons.school);
    expect(directory.newJersey.single.items.single.phone, isNull);
    expect(directory.national.single.items.single.phoneLabel, '800-342-9647');
    // Unknown icon keys fall back instead of failing
    expect(directory.national.single.iconData, Icons.link);
  });

  test('CurrentUser display name and initials for the home header', () {
    final soldier = CurrentUser.fromJson(
      jsonDecode(
        '{"id":11,"email":"pat@example.com","role":"soldier","unitId":2,'
        '"unitName":"HHC","firstName":"Pat","lastName":"Soldier",'
        '"rank":"SGT","dutyRoleLabel":"Team Leader",'
        '"position":"2nd Squad, 1st Platoon"}',
      ),
    );
    final admin = CurrentUser.fromJson(
      jsonDecode(
        '{"id":4,"email":"felix@example.com","role":"admin","unitId":null,'
        '"unitName":null,"firstName":null,"lastName":null,"rank":null,'
        '"dutyRoleLabel":null,"position":null}',
      ),
    );

    expect(soldier.displayName, 'SGT Pat Soldier');
    expect(soldier.initials, 'PS');
    expect(soldier.position, '2nd Squad, 1st Platoon');
    expect(admin.displayName, 'felix@example.com');
    expect(admin.initials, 'F');
  });
}
