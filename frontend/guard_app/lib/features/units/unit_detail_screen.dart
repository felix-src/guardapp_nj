import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import 'unit.dart';
import 'unit_api.dart';
import 'unit_manage_screen.dart';
import '../org/org_chart_screen.dart';

class UnitDetailScreen extends StatefulWidget {
  final int unitId;
  final String unitName;

  const UnitDetailScreen({
    super.key,
    required this.unitId,
    required this.unitName,
  });

  @override
  State<UnitDetailScreen> createState() => _UnitDetailScreenState();
}

class _UnitDetailScreenState extends State<UnitDetailScreen> {
  late Future<Unit> _unit;

  @override
  void initState() {
    super.initState();
    _unit = UnitApi.fetchUnit(widget.unitId);
  }

  Future<void> _refresh() async {
    final unit = UnitApi.fetchUnit(widget.unitId);
    setState(() => _unit = unit);
    await unit;
  }

  Future<void> _launch(Uri uri) async {
    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${uri.scheme} link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.unitName),
        actions: [
          if (Session.user?.canViewUnitChart(widget.unitId) ?? false)
            IconButton(
              icon: const Icon(Icons.account_tree),
              tooltip: 'Org chart',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrgChartScreen(
                    unitId: widget.unitId,
                    unitName: widget.unitName,
                  ),
                ),
              ),
            ),
          if (Session.user?.canManageUnit(widget.unitId) ?? false)
            IconButton(
              icon: const Icon(Icons.manage_accounts),
              tooltip: 'Manage unit',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UnitManageScreen(unitId: widget.unitId),
                  ),
                );
                // Contacts may have changed
                if (mounted) _refresh();
              },
            ),
        ],
      ),
      body: FutureBuilder<Unit>(
        future: _unit,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Failed to load unit'),
                  TextButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            );
          }

          final unit = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              children: [
                GroupedSection(
                  children: [
                    NavRow(
                      icon: Icons.location_on,
                      gradient: GuardColors.badgeGradients[2],
                      title: 'State',
                      subtitle: unit.state,
                    ),
                  ],
                ),
                if (unit.contacts.isEmpty)
                  const GroupedSection(
                    title: 'Points of contact',
                    children: [
                      ListTile(title: Text('No points of contact listed')),
                    ],
                  ),
                for (final contact in unit.contacts)
                  _ContactCard(
                    contact: contact,
                    onLaunch: _launch,
                    showTitle: contact == unit.contacts.first,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// One point of contact as its own grouped card: who, then call / email.
class _ContactCard extends StatelessWidget {
  final PointOfContact contact;
  final Future<void> Function(Uri) onLaunch;
  final bool showTitle;

  const _ContactCard({
    required this.contact,
    required this.onLaunch,
    this.showTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final phone = contact.phone;
    final email = contact.email;

    return GroupedSection(
      title: showTitle ? 'Points of contact' : null,
      children: [
        NavRow(
          icon: Icons.person,
          title: contact.name,
          subtitle: contact.position,
        ),
        if (phone != null)
          NavRow(
            icon: Icons.phone,
            gradient: GuardColors.badgeGradients[0],
            title: phone,
            onTap: () => onLaunch(Uri(scheme: 'tel', path: phone)),
          ),
        if (email != null)
          NavRow(
            icon: Icons.email,
            gradient: GuardColors.badgeGradients[1],
            title: email,
            onTap: () => onLaunch(Uri(scheme: 'mailto', path: email)),
          ),
      ],
    );
  }
}
