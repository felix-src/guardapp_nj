import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'resource_models.dart';
import 'resource_widgets.dart';

enum _Region { newJersey, national }

/// Resources & benefits for Guard members, in New Jersey and nationally.
class ResourcesScreen extends StatefulWidget {
  /// Replaceable in tests; defaults to the server.
  final Future<ResourceDirectory> Function() load;

  const ResourcesScreen({super.key, this.load = ResourceApi.fetchResources});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  late Future<ResourceDirectory> _directory;
  _Region _region = _Region.newJersey;

  @override
  void initState() {
    super.initState();
    _directory = widget.load();
  }

  void _retry() => setState(() => _directory = widget.load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resources & Benefits')),
      body: FutureBuilder<ResourceDirectory>(
        future: _directory,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (snapshot.hasError) {
            return LoadFailed(
              message: 'Failed to load resources',
              onRetry: _retry,
            );
          }

          final directory = snapshot.data!;
          final groups = _region == _Region.newJersey
              ? directory.newJersey
              : directory.national;

          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: CupertinoSlidingSegmentedControl<_Region>(
                  groupValue: _region,
                  thumbColor: Theme.of(context).colorScheme.surface,
                  onValueChanged: (value) {
                    if (value != null) setState(() => _region = value);
                  },
                  children: const {
                    _Region.newJersey: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('New Jersey'),
                    ),
                    _Region.national: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('National'),
                    ),
                  },
                ),
              ),
              CrisisLineCard(line: directory.crisisLine),
              for (final (i, group) in groups.indexed)
                ResourceGroupSection(
                  group: group,
                  gradient: GuardColors
                      .badgeGradients[i % GuardColors.badgeGradients.length],
                ),
            ],
          );
        },
      ),
    );
  }
}
