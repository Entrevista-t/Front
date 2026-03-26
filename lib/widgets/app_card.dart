import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A reusable card container that matches the enterprise dark theme.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? borderRadius;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius ?? kRadiusMd);
    final container = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(kS24),
      decoration: BoxDecoration(
        color: color ?? kBgSurface,
        borderRadius: radius,
        border: Border.all(color: kBorderSubtle),
      ),
      child: child,
    );
    if (onTap == null) return container;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: kAccent.withValues(alpha: 0.08),
        highlightColor: kAccent.withValues(alpha: 0.04),
        child: container,
      ),
    );
  }
}
