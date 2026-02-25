import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../memos/memo_download.dart';
import '../../core/token_storage.dart';
import '../../core/config.dart';
import '../memos/memo_api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _memos = [];
  bool _loadingMemos = true;

  @override
  void initState() {
    super.initState();
    _enforceAuth();
    _loadMemos();
  }

  Future<void> _enforceAuth() async {
    final token = await TokenStorage.read();
    if (token == null && mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Future<void> _loadMemos() async {
    try {
      final memos = await MemoApi.fetchMemos();
      setState(() {
        _memos = memos;
        _loadingMemos = false;
      });
    } catch (e) {
      print('FAILED TO LOAD MEMOS: $e');
      setState(() {
        _loadingMemos = false;
      });
    }
  }

  Future<void> _logout() async {
    await TokenStorage.clear();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _loadingMemos
          ? const Center(child: CircularProgressIndicator())
          : _memos.isEmpty
          ? const Center(child: Text('No memos available'))
          : ListView.builder(
              itemCount: _memos.length,
              itemBuilder: (context, index) {
                final memo = _memos[index];
                return ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: Text(memo['title']),
                  subtitle: Text(
                    memo['createdAt'],
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () async {
                    try {
                      await MemoDownload.downloadAndOpen(
                        memoId: memo['id'],
                        filename: memo['filename'],
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to open memo')),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
