import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A reusable card container matching the Editorial Tech light theme.
/// Supports optional hover elevation, gradient border, and tap callbacks.
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? borderRadius;
  final VoidCallback? onTap;
  final bool hoverable;
  final bool gradientBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius,
    this.onTap,
    this.hoverable = false,
    this.gradientBorder = false,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius ?? kRadiusMd);
    final isInteractive = widget.onTap != null || widget.hoverable;

    Widget card;

    if (widget.gradientBorder) {
      card = Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: _hovering ? context.colors.gradientCardBorder : null,
          border: _hovering ? null : Border.all(color: context.colors.borderSubtle),
          boxShadow: _hovering ? kShadowMd : null,
        ),
        child: Container(
          width: double.infinity,
          padding: widget.padding ?? const EdgeInsets.all(kS24),
          margin: widget.gradientBorder && _hovering
              ? const EdgeInsets.all(1)
              : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: widget.color ?? context.colors.bgSurface,
            borderRadius: radius,
          ),
          child: widget.child,
        ),
      );
    } else {
      card = AnimatedContainer(
        duration: kDurationFast,
        curve: kCurveHover,
        width: double.infinity,
        padding: widget.padding ?? const EdgeInsets.all(kS24),
        decoration: BoxDecoration(
          color: widget.color ?? context.colors.bgSurface,
          borderRadius: radius,
          border: Border.all(
            color: _hovering ? context.colors.borderStrong : context.colors.borderSubtle,
          ),
          boxShadow: _hovering ? kShadowMd : kShadowSm,
        ),
        child: widget.child,
      );
    }

    if (!isInteractive) return card;

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovering ? 1.01 : 1.0,
          duration: kDurationFast,
          curve: kCurveHover,
          child: card,
        ),
      ),
    );
  }
}
