import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A semi-transparent glassmorphism container with backdrop blur.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.blur = kBlurGlass,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius ?? kRadiusGlass);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(kS20),
          decoration: BoxDecoration(
            color: backgroundColor ?? context.colors.glassBg,
            borderRadius: radius,
            border: Border.all(
              color: borderColor ?? context.colors.glassBorder,
              width: 1,
            ),
            boxShadow: kShadowGlass,
          ),
          child: child,
        ),
      ),
    );
  }
}
