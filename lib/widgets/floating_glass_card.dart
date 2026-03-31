import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A glassmorphism card that floats with a subtle translate + rotate animation.
/// Used on the landing page periphery to create depth.
class FloatingGlassCard extends StatefulWidget {
  final Widget child;
  final double width;
  final Duration delay;
  final double opacity;

  const FloatingGlassCard({
    super.key,
    required this.child,
    this.width = 280,
    this.delay = Duration.zero,
    this.opacity = 0.55,
  });

  @override
  State<FloatingGlassCard> createState() => _FloatingGlassCardState();
}

class _FloatingGlassCardState extends State<FloatingGlassCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: kDurationFloat,
    );
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = _ctrl.value;
        // Keyframes: 0%→33%→66%→100%
        double dx, dy, rotate;
        if (t < 0.33) {
          final p = t / 0.33;
          dx = 10 * p;
          dy = -20 * p;
          rotate = 2 * p * (pi / 180);
        } else if (t < 0.66) {
          final p = (t - 0.33) / 0.33;
          dx = 10 - 25 * p;
          dy = -20 + 30 * p;
          rotate = (2 - 3 * p) * (pi / 180);
        } else {
          final p = (t - 0.66) / 0.34;
          dx = -15 + 15 * p;
          dy = 10 - 10 * p;
          rotate = (-1 + 1 * p) * (pi / 180);
        }
        return Transform(
          transform: Matrix4.identity()
            ..translate(dx, dy)
            ..rotateZ(rotate),
          alignment: Alignment.center,
          child: child,
        );
      },
      child: Opacity(
        opacity: widget.opacity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kRadiusGlass),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: kBlurGlass, sigmaY: kBlurGlass),
            child: Container(
              width: widget.width,
              padding: const EdgeInsets.all(kS20),
              decoration: BoxDecoration(
                color: context.colors.glassBg,
                borderRadius: BorderRadius.circular(kRadiusGlass),
                border: Border.all(color: context.colors.glassBorder, width: 1),
                boxShadow: kShadowGlass,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
