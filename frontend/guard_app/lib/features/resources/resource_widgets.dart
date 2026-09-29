import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../core/ui.dart';
import 'resource_models.dart';

/// Opens [url] in the in-app browser (Safari view controller on iPhone).
Future<void> openResourceLink(BuildContext context, String url) async {
  final opened = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.inAppBrowserView,
  );
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not open link')));
  }
}

Future<void> callNumber(BuildContext context, String phone) async {
  final opened = await launchUrl(Uri(scheme: 'tel', path: phone));
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not start a call')));
  }
}

/// One [ResourceGroup] as an inset grouped list.
class ResourceGroupSection extends StatelessWidget {
  final ResourceGroup group;
  final Gradient gradient;

  const ResourceGroupSection({
    super.key,
    required this.group,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GroupedSection(
      title: group.title,
      children: [
        for (final item in group.items)
          ResourceRow(item: item, icon: group.iconData, gradient: gradient),
      ],
    );
  }
}

class ResourceRow extends StatelessWidget {
  final ResourceLink item;
  final IconData icon;
  final Gradient gradient;

  const ResourceRow({
    super.key,
    required this.item,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final phone = item.phone;
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => openResourceLink(context, item.url),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(icon: icon, gradient: gradient),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.description,
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.75),
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                  if (phone != null) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => callNumber(context, phone),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone, size: 16, color: colors.primary),
                          const SizedBox(width: 4),
                          Text(
                            item.phoneLabel ?? phone,
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              size: 18,
              color: colors.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

/// Prominent card for the Military & Veterans Crisis Line.
class CrisisLineCard extends StatelessWidget {
  final ResourceLink line;

  const CrisisLineCard({super.key, required this.line});

  @override
  Widget build(BuildContext context) {
    final phone = line.phone;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [GuardColors.brown, Color(0xFF4A3322)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, color: GuardColors.tan),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  line.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            line.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          // Wrap, not Row: narrow iPhones and large text sizes need room
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (phone != null)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: GuardColors.tan,
                    foregroundColor: GuardColors.ink,
                  ),
                  onPressed: () => callNumber(context, phone),
                  icon: const Icon(Icons.phone),
                  // The description says to press 1 after dialing
                  label: Text('Call $phone'),
                ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () => openResourceLink(context, line.url),
                child: const Text('Website'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Loading / error body shared by the resource screens.
class LoadFailed extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const LoadFailed({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
