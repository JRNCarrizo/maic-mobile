import 'package:flutter/material.dart';

import '../theme/maic_colors.dart';

class MaicBackdrop extends StatelessWidget {
  const MaicBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [MaicColors.bgTop, MaicColors.bgMid, MaicColors.bgBottom],
        ),
      ),
      child: child,
    );
  }
}

class MaicPanel extends StatelessWidget {
  const MaicPanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MaicColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MaicColors.panelBorder),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: padding ?? const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: child,
        ),
      ),
    );
  }
}

class MaicIconBadge extends StatelessWidget {
  const MaicIconBadge({super.key, required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? MaicColors.accent;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: MaicColors.accentSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: accent),
    );
  }
}

class MaicSectionTitle extends StatelessWidget {
  const MaicSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        letterSpacing: 0.6,
        color: MaicColors.muted,
      ),
    );
  }
}
