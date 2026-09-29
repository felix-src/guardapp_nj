import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'resource_models.dart';
import 'resource_widgets.dart';

/// NJ Guard federal technician and AGR job listings, plus USAJOBS.
class JobsScreen extends StatefulWidget {
  /// Replaceable in tests; defaults to the server.
  final Future<List<ResourceGroup>> Function() load;

  const JobsScreen({super.key, this.load = ResourceApi.fetchJobs});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  late Future<List<ResourceGroup>> _sections;

  @override
  void initState() {
    super.initState();
    _sections = widget.load();
  }

  void _retry() => setState(() => _sections = widget.load());

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.75);

    return Scaffold(
      appBar: AppBar(title: const Text('Jobs')),
      body: FutureBuilder<List<ResourceGroup>>(
        future: _sections,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (snapshot.hasError) {
            return LoadFailed(message: 'Failed to load jobs', onRetry: _retry);
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 8, 32, 20),
                child: Text(
                  'Full-time jobs with the New Jersey National Guard. '
                  'Listings open on the official NJ Department of Military '
                  'Affairs site and USAJOBS.',
                  style: TextStyle(color: muted, height: 1.3),
                ),
              ),
              for (final (i, section) in snapshot.data!.indexed)
                ResourceGroupSection(
                  group: section,
                  gradient:
                      GuardColors.badgeGradients[(i + 3) %
                          GuardColors.badgeGradients.length],
                ),
            ],
          );
        },
      ),
    );
  }
}
