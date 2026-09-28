import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../../core/authed_http.dart';

class MemoDownload {
  static Future<void> downloadAndOpen({
    required int memoId,
    required String filename,
  }) async {
    final response = await authedGet('/memos/$memoId/download');

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
