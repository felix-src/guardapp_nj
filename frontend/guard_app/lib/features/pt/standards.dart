import 'dart:convert';

import 'package:flutter/services.dart';

import 'pt_standard.dart';

/// Every fitness test standard bundled with the app, oldest first. Bundled
/// (not downloaded) so scoring works in the field without signal.
///
/// To add new tables: generate a JSON file with tool/pt_standards/, add it
/// to pubspec.yaml assets and to this list. [PtStandards.current] picks the
/// newest one already in effect.
const standardAssets = ['assets/pt_standards/aft_2025-06-01.json'];

class PtStandards {
  static List<PtStandard>? _cache;

  static Future<List<PtStandard>> all({AssetBundle? bundle}) async {
    return _cache ??= [
      for (final path in standardAssets)
        PtStandard.fromJson(
          jsonDecode(await (bundle ?? rootBundle).loadString(path)),
        ),
    ]..sort((a, b) => a.effective.compareTo(b.effective));
  }

  /// The newest standard in effect on [date] (default: today).
  static Future<PtStandard> current({
    DateTime? date,
    AssetBundle? bundle,
  }) async {
    final today = date ?? DateTime.now();
    final standards = await all(bundle: bundle);
    return standards.lastWhere(
      (s) => !s.effective.isAfter(today),
      orElse: () => standards.first,
    );
  }
}
