import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/authed_http.dart';
import '../../core/config.dart';
import 'org_models.dart';

class JoinCodeException implements Exception {
  final String message;
  JoinCodeException(this.message);

  @override
  String toString() => message;
}

class OrgApi {
  /// Public: checks a unit code and returns the unit's structure for the
  /// sign-up form. Throws [JoinCodeException] with a message for the user.
  static Future<JoinInfo> fetchJoinInfo(String code) async {
    final http.Response response;
    try {
      response = await http.get(
        Uri.parse('$apiBaseUrl/auth/join/${Uri.encodeComponent(code)}'),
      );
    } catch (_) {
      throw JoinCodeException('Could not reach the server');
    }

    if (response.statusCode == 200) {
      return JoinInfo.fromJson(jsonDecode(response.body));
    }
    if (response.statusCode == 429) {
      throw JoinCodeException(
        'Too many attempts. Wait a minute and try again.',
      );
    }
    throw JoinCodeException(
      errorMessage(response) ?? 'Could not check that code',
    );
  }

  static Future<OrgChart> fetchOrgChart(int unitId) async {
    final response = await authedGet('/units/$unitId/org-chart');
    return OrgChart.fromJson(decodeOrThrow(response, 200));
  }

  /// A platoon when [parentId] is null, otherwise an HQ/squad in that platoon.
  static Future<void> addElement(
    int unitId, {
    required String name,
    required String kind,
    int? parentId,
  }) async {
    final response = await authedPost(
      '/units/$unitId/org-elements',
      body: {'name': name, 'kind': kind, 'parentId': ?parentId},
    );
    decodeOrThrow(response, 201);
  }

  static Future<void> renameElement(
    int unitId,
    int elementId,
    String name,
  ) async {
    final response = await authedPatch(
      '/units/$unitId/org-elements/$elementId',
      body: {'name': name},
    );
    decodeOrThrow(response, 200);
  }

  static Future<void> deleteElement(int unitId, int elementId) async {
    final response = await authedDelete(
      '/units/$unitId/org-elements/$elementId',
    );
    decodeOrThrow(response, 204);
  }

  static Future<void> setPosition(
    int unitId,
    int userId, {
    required int orgElementId,
    required String dutyRole,
  }) async {
    final response = await authedPatch(
      '/units/$unitId/members/$userId/position',
      body: {'orgElementId': orgElementId, 'dutyRole': dutyRole},
    );
    decodeOrThrow(response, 200);
  }
}
