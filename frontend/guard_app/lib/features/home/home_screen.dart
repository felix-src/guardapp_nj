import 'package:flutter/material.dart';
import '../memos/memo_download.dart';
import '../../core/token_storage.dart';
import '../memos/memo_api.dart';
import '../../core/session.dart';
import '../units/unit_manage_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _memos = [];
  bool _loadingMemos = true;
  CurrentUser? _user = Session.user;

  @override
  void initState() {
    super.initState();
    _enforceAuth();
    _loadMemos();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final user = await Session.load();
      if (mounted) setState(() => _user = user);
    } catch (e) {
      debugPrint('FAILED TO LOAD PROFILE: $e');
    }
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
      if (!mounted) return;
      setState(() {
        _memos = memos;
        _loadingMemos = false;
      });
    } catch (e) {
      debugPrint('FAILED TO LOAD MEMOS: $e');
      if (!mounted) return;
      setState(() {
        _loadingMemos = false;
      });
    }
  }

  Future<void> _logout() async {
    await TokenStorage.clear();
    Session.clear();
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
          if (_user case CurrentUser(
            isReadinessNco: true,
            unitId: final int unitId,
          ))
            IconButton(
              icon: const Icon(Icons.manage_accounts),
              tooltip: 'My unit',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UnitManageScreen(unitId: unitId),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.groups),
            tooltip: 'Units',
            onPressed: () => Navigator.pushNamed(context, '/units'),
          ),
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
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to open memo')),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
