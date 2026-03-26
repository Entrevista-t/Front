import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// An icon rendered inside a tinted rounded square with a soft radial glow.
/// Replaces the repetitive Container(color: accent.withAlpha(0.12), child: Icon(...)) pattern.
class GlowIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final bool glow;

  const GlowIcon({
    super.key,
    required this.icon,
    this.color = kAccent,
    this.size = 44,
    this.iconSize = 22,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(kRadiusMd),
        boxShadow: glow
            ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 12, spreadRadius: 1)]
            : null,
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}
