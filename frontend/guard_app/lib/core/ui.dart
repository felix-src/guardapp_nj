import 'package:flutter/material.dart';

import 'theme.dart';

/// Rounded-square icon on a gradient, like iOS Settings icons.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final double size;

  const IconBadge({
    super.key,
    required this.icon,
    this.gradient = GuardColors.heroGradient,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.58),
    );
  }
}

/// iOS "inset grouped" list section: small caps header, then a rounded card
/// of rows separated by hairlines.
class GroupedSection extends StatelessWidget {
  final String? title;
  final String? footer;
  final List<Widget> children;

  const GroupedSection({
    super.key,
    this.title,
    this.footer,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.68);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 6),
              child: Text(
                title!.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 0.3,
                  color: muted,
                ),
              ),
            ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Divider(indent: 60),
                  children[i],
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 6, 32, 0),
              child: Text(
                footer!,
                style: TextStyle(fontSize: 13, color: muted),
              ),
            ),
        ],
      ),
    );
  }
}

/// A row in a [GroupedSection]: badge, title, optional subtitle, chevron.
class NavRow extends StatelessWidget {
  final IconData icon;
  final Gradient? gradient;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const NavRow({
    super.key,
    required this.icon,
    required this.title,
    this.gradient,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.35);

    return ListTile(
      onTap: onTap,
      leading: IconBadge(
        icon: icon,
        gradient: gradient ?? GuardColors.heroGradient,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing:
          trailing ??
          (onTap == null ? null : Icon(Icons.chevron_right, color: muted)),
    );
  }
}

/// Gradient header with rounded bottom corners; extends under the status bar.
class HeroHeader extends StatelessWidget {
  final Widget child;

  const HeroHeader({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: GuardColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: child,
        ),
      ),
    );
  }
}

/// Full-screen brand gradient with a centered card, for sign-in and sign-up.
class BrandedFormScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool showBack;

  const BrandedFormScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: showBack
          ? AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(gradient: GuardColors.heroGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    const BrandMark(),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 15,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shield mark with the "NEW JERSEY NATIONAL GUARD" caption. A generic icon,
/// not official insignia.
class BrandMark extends StatelessWidget {
  final bool compact;

  const BrandMark({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final caption = Text(
      'NEW JERSEY NATIONAL GUARD',
      style: TextStyle(
        color: GuardColors.tan,
        fontSize: compact ? 11 : 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
      ),
    );
    if (compact) return caption;

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(color: GuardColors.tan.withValues(alpha: 0.6)),
          ),
          child: const Icon(Icons.shield, color: GuardColors.tan, size: 34),
        ),
        const SizedBox(height: 12),
        caption,
      ],
    );
  }
}

/// Error text in the theme's error color.
class ErrorText extends StatelessWidget {
  final String message;

  const ErrorText(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
