import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'unit.dart';
import 'unit_api.dart';

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
      appBar: AppBar(title: Text(widget.unitName)),
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
              children: [
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('State'),
                  subtitle: Text(unit.state),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Points of Contact',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (unit.contacts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No points of contact listed'),
                  ),
                for (final contact in unit.contacts)
                  _ContactCard(contact: contact, onLaunch: _launch),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final PointOfContact contact;
  final Future<void> Function(Uri) onLaunch;

  const _ContactCard({required this.contact, required this.onLaunch});

  @override
  Widget build(BuildContext context) {
    final phone = contact.phone;
    final email = contact.email;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(contact.name),
              subtitle: Text(contact.position),
            ),
            if (phone != null)
              ListTile(
                dense: true,
                leading: const Icon(Icons.phone_outlined),
                title: Text(phone),
                onTap: () => onLaunch(Uri(scheme: 'tel', path: phone)),
              ),
            if (email != null)
              ListTile(
                dense: true,
                leading: const Icon(Icons.email_outlined),
                title: Text(email),
                onTap: () => onLaunch(Uri(scheme: 'mailto', path: email)),
              ),
          ],
        ),
      ),
    );
  }
}
