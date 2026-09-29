import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import 'memo_api.dart';
import 'memo_download.dart';

/// Command memos (PDFs), newest first.
class MemosScreen extends StatefulWidget {
  const MemosScreen({super.key});

  @override
  State<MemosScreen> createState() => _MemosScreenState();
}

class _MemosScreenState extends State<MemosScreen> {
  late Future<List<dynamic>> _memos;
  int? _opening;

  @override
  void initState() {
    super.initState();
    _memos = MemoApi.fetchMemos();
  }

  Future<void> _refresh() async {
    final memos = MemoApi.fetchMemos();
    setState(() => _memos = memos);
    await memos;
  }

  Future<void> _open(Map<String, dynamic> memo) async {
    setState(() => _opening = memo['id']);
    try {
      await MemoDownload.downloadAndOpen(
        memoId: memo['id'],
        filename: memo['filename'],
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to open memo')));
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memos')),
      body: FutureBuilder<List<dynamic>>(
        future: _memos,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Failed to load memos'),
                  TextButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            );
          }

          final memos = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              children: [
                if (memos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No memos yet')),
                  )
                else
                  GroupedSection(
                    title: 'Command memos',
                    children: [
                      for (final memo in memos.cast<Map<String, dynamic>>())
                        NavRow(
                          icon: Icons.description,
                          gradient: GuardColors.badgeGradients[1],
                          title: memo['title'],
                          subtitle: formatDate(
                            DateTime.parse(memo['createdAt']).toLocal(),
                          ),
                          trailing: _opening == memo['id']
                              ? const CupertinoActivityIndicator()
                              : null,
                          onTap: _opening == null ? () => _open(memo) : null,
                        ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
