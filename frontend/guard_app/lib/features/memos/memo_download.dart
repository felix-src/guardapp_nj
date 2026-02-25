import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../../core/config.dart';
import '../../core/token_storage.dart';

class MemoDownload {
  static Future<void> downloadAndOpen({
    required int memoId,
    required String filename,
  }) async {
    final token = await TokenStorage.read();
    if (token == null) {
      throw Exception('No auth token available');
    }

    final uri = Uri.parse('$apiBaseUrl/memos/$memoId/download');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to download memo (status ${response.statusCode})',
      );
    }

    final Uint8List bytes = response.bodyBytes;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');

    await file.writeAsBytes(bytes, flush: true);

    await OpenFilex.open(file.path);
  }
}
