import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/token_storage.dart';
import '../../core/ui.dart';
import '../auth/change_password_dialog.dart';
import '../memos/memos_screen.dart';
import '../org/org_chart_screen.dart';
import '../pt/pt_hub_screen.dart';
import '../resources/jobs_screen.dart';
import '../resources/resources_screen.dart';
import '../units/unit_detail_screen.dart';
import '../units/unit_manage_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CurrentUser? _user = Session.user;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _enforceAuth();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final user = await Session.load();
      if (mounted) {
        setState(() {
          _user = user;
          _loadFailed = false;
        });
      }
    } catch (e) {
      debugPrint('FAILED TO LOAD PROFILE: $e');
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _enforceAuth() async {
    final token = await TokenStorage.read();
    if (token == null && mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Future<void> _logout() async {
    await TokenStorage.clear();
    Session.clear();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Future<void> _changePassword() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => const ChangePasswordDialog(),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed. Other devices were signed out.'),
        ),
      );
    }
  }

  /// For a lost phone: ends every session, including this one.
  Future<void> _logoutAllDevices() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Sign out of all devices?'),
        content: const Text(
          'Use this if a phone is lost or stolen. You will need to sign in '
          'again everywhere, including here.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out All'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await AuthApi.logoutAllDevices();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not reach the server')),
      );
    }
  }

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _showAccountSheet(CurrentUser user) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(user.displayName),
        message: Text(user.email),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _changePassword();
            },
            child: const Text('Change Password'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _logoutAllDevices();
            },
            child: const Text('Sign Out of All Devices'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text('Sign Out'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  List<_Feature> _features(CurrentUser user) {
    final unitId = user.unitId;
    return [
      if (unitId != null) ...[
        _Feature(
          'Org Chart',
          'Platoons, squads & roles',
          Icons.account_tree,
          () => _open(OrgChartScreen(unitId: unitId, unitName: user.unitName)),
        ),
        _Feature(
          'My Unit',
          'Points of contact',
          Icons.shield,
          () => _open(
            UnitDetailScreen(unitId: unitId, unitName: user.unitName ?? ''),
          ),
        ),
      ],
      _Feature(
        'Memos',
        'Command memos',
        Icons.description,
        () => _open(const MemosScreen()),
      ),
      _Feature(
        'PT Test',
        'AFT calculator, timers & laps',
        Icons.fitness_center,
        () => _open(const PtHubScreen()),
      ),
      _Feature(
        'Resources',
        'Benefits in NJ & nationally',
        Icons.volunteer_activism,
        () => _open(const ResourcesScreen()),
      ),
      _Feature(
        'Jobs',
        'Technician & AGR listings',
        Icons.work,
        () => _open(const JobsScreen()),
      ),
      if (user.isReadinessNco && unitId != null)
        _Feature(
          'Manage Unit',
          'Sign-up link & members',
          Icons.manage_accounts,
          () => _open(UnitManageScreen(unitId: unitId)),
        ),
      if (user.isAdmin)
        _Feature(
          'All Units',
          'Admin',
          Icons.groups,
          () => Navigator.pushNamed(context, '/units'),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return Scaffold(
      body: user == null
          ? Center(
              child: _loadFailed
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Could not load your profile'),
                        TextButton(
                          onPressed: _loadSession,
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  : const CupertinoActivityIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadSession,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _Header(
                      user: user,
                      onAccount: () => _showAccountSheet(user),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    sliver: SliverGrid.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.15,
                      children: [
                        for (final (i, feature) in _features(user).indexed)
                          _FeatureTile(
                            feature: feature,
                            gradient:
                                GuardColors.badgeGradients[i %
                                    GuardColors.badgeGradients.length],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Header extends StatelessWidget {
  final CurrentUser user;
  final VoidCallback onAccount;

  const _Header({required this.user, required this.onAccount});

  @override
  Widget build(BuildContext context) {
    final soft = Colors.white.withValues(alpha: 0.85);
    final textTheme = Theme.of(context).textTheme;
    final roleLine = [
      user.dutyRoleLabel,
      user.position,
    ].whereType<String>().join(' · ');

    return HeroHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: BrandMark(compact: true)),
              GestureDetector(
                onTap: onAccount,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: GuardColors.tan,
                  foregroundColor: GuardColors.ink,
                  child: Text(
                    user.initials,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            user.displayName,
            style: textTheme.headlineLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.shield, color: GuardColors.tan, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  user.unitName ?? (user.isAdmin ? 'Administrator' : 'No unit'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (roleLine.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(roleLine, style: TextStyle(color: soft)),
            ),
          ],
        ],
      ),
    );
  }
}

class _Feature {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  _Feature(this.title, this.subtitle, this.icon, this.onTap);
}

class _FeatureTile extends StatelessWidget {
  final _Feature feature;
  final Gradient gradient;

  const _FeatureTile({required this.feature, required this.gradient});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.72);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: feature.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(icon: feature.icon, gradient: gradient, size: 44),
              // Fixed gap (not a Spacer) so titles line up across the grid
              const SizedBox(height: 14),
              Text(
                feature.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                feature.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: muted, height: 1.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
