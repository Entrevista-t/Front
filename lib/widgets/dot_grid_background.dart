import 'dart:math' show sin, cos, pi;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Paints a subtle radial dot grid pattern.
/// Optionally renders blurred glow spheres in background corners.
class DotGridBackground extends StatefulWidget {
  final Widget child;
  final bool showGlows;

  const DotGridBackground({
    super.key,
    required this.child,
    this.showGlows = true,
  });

  @override
  State<DotGridBackground> createState() => _DotGridBackgroundState();
}

class _DotGridBackgroundState extends State<DotGridBackground>
    with SingleTickerProviderStateMixin {
  AnimationController? _anim;

  @override
  void initState() {
    super.initState();
    if (widget.showGlows) {
      _anim = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 20),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _anim?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (!widget.showGlows) {
      return Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DotGridPainter(
                dotColor: colors.dotGridColor,
                dotOpacity: colors.dotGridOpacity,
              ),
            ),
          ),
          Positioned.fill(child: widget.child),
        ],
      );
    }

    return AnimatedBuilder(
      animation: _anim!,
      builder: (context, _) {
        final dx = 15 * sin(_anim!.value * 2 * pi);
        final dy = 10 * cos(_anim!.value * 2 * pi);

        return Stack(
          children: [
            // Dot grid layer
            Positioned.fill(
              child: CustomPaint(
                painter: _DotGridPainter(
                  dotColor: colors.dotGridColor,
                  dotOpacity: colors.dotGridOpacity,
                ),
              ),
            ),
            // Decorative glow spheres
            Positioned(
              top: -100 + dy,
              left: -80 + dx,
              child: _GlowSphere(
                color: colors.glowBlue,
                size: MediaQuery.of(context).size.width * 0.4,
              ),
            ),
            Positioned(
              bottom: -100 - dy,
              right: -80 - dx,
              child: _GlowSphere(
                color: colors.glowSlate,
                size: MediaQuery.of(context).size.width * 0.4,
              ),
            ),
            // Content
            Positioned.fill(child: widget.child),
          ],
        );
      },
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final Color dotColor;
  final double dotOpacity;

  _DotGridPainter({required this.dotColor, required this.dotOpacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor.withValues(alpha: dotOpacity)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += 40.0) {
      for (double y = 0; y < size.height; y += 40.0) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) =>
      dotColor != oldDelegate.dotColor || dotOpacity != oldDelegate.dotOpacity;
}

class _GlowSphere extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowSphere({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 120,
            spreadRadius: 40,
          ),
        ],
      ),
    );
  }
}
