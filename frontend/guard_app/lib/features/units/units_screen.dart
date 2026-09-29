import 'package:flutter/material.dart';

import '../../core/ui.dart';

import 'unit.dart';
import 'unit_api.dart';
import 'unit_detail_screen.dart';

class UnitsScreen extends StatefulWidget {
  const UnitsScreen({super.key});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  late Future<List<Unit>> _units;

  @override
  void initState() {
    super.initState();
    _units = UnitApi.fetchUnits();
  }

  Future<void> _refresh() async {
    final units = UnitApi.fetchUnits();
    setState(() => _units = units);
    await units;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Units')),
      body: FutureBuilder<List<Unit>>(
        future: _units,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Failed to load units'),
                  TextButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            );
          }

          final units = snapshot.data!;
          if (units.isEmpty) {
            return const Center(child: Text('No units available'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              children: [
                GroupedSection(
                  title: '${units.length} units',
                  children: [
                    for (final unit in units)
                      NavRow(
                        icon: Icons.shield,
                        title: unit.name,
                        subtitle: unit.state,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UnitDetailScreen(
                              unitId: unit.id,
                              unitName: unit.name,
                            ),
                          ),
                        ),
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
