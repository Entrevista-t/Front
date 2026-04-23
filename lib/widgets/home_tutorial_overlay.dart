import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart' show kFontSerif, kFontSans;

// ═══════════════════════════════════════════════════════════════════════════
// Tutorial step data
// ═══════════════════════════════════════════════════════════════════════════

class TutorialStep {
  final String title;
  final String description;
  final GlobalKey targetKey;
  final IconData icon;
  final Color accentColor;

  const TutorialStep({
    required this.title,
    required this.description,
    required this.targetKey,
    required this.icon,
    required this.accentColor,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Public API
// ═══════════════════════════════════════════════════════════════════════════

/// Starts a spotlight tutorial overlay on the current screen.
/// Returns a Future that completes when the user finishes or skips the tutorial.
Future<void> startHomeTutorial(BuildContext context, List<TutorialStep> steps) {
  final completer = Completer<void>();
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _TutorialOverlay(
      steps: steps,
      onFinish: () {
        entry.remove();
        if (!completer.isCompleted) completer.complete();
      },
    ),
  );

  Overlay.of(context).insert(entry);
  return completer.future;
}

// ═══════════════════════════════════════════════════════════════════════════
// Tutorial overlay widget
// ═══════════════════════════════════════════════════════════════════════════

class _TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onFinish;

  const _TutorialOverlay({required this.steps, required this.onFinish});

  @override
  State<_TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<_TutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _computeTarget();
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _computeTarget() {
    final step = widget.steps[_currentStep];
    final renderObj = step.targetKey.currentContext?.findRenderObject();
    if (renderObj is RenderBox && renderObj.hasSize) {
      final offset = renderObj.localToGlobal(Offset.zero);
      _targetRect = offset & renderObj.size;
    } else {
      _targetRect = null;
    }
  }

  void _next() {
    if (_currentStep >= widget.steps.length - 1) {
      _dismiss();
      return;
    }
    _animCtrl.reverse().then((_) {
      setState(() {
        _currentStep++;
        _computeTarget();
      });
      _animCtrl.forward();
    });
  }

  void _prev() {
    if (_currentStep <= 0) return;
    _animCtrl.reverse().then((_) {
      setState(() {
        _currentStep--;
        _computeTarget();
      });
      _animCtrl.forward();
    });
  }

  void _dismiss() {
    _animCtrl.reverse().then((_) => widget.onFinish());
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    final screen = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final isFirst = _currentStep == 0;
    final isLast = _currentStep == widget.steps.length - 1;

    // Expand target rect with padding for the spotlight
    final spotlightPadding = 10.0;
    final spotRect = _targetRect != null
        ? Rect.fromLTRB(
            _targetRect!.left - spotlightPadding,
            _targetRect!.top - spotlightPadding,
            _targetRect!.right + spotlightPadding,
            _targetRect!.bottom + spotlightPadding,
          )
        : Rect.fromCenter(
            center: Offset(screen.width / 2, screen.height / 2),
            width: 200,
            height: 100,
          );

    return FadeTransition(
      opacity: _fadeAnim,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // ── Dark backdrop with spotlight cutout ──
            Positioned.fill(
              child: GestureDetector(
                onTap: () {}, // absorb taps
                child: CustomPaint(
                  painter: _SpotlightPainter(
                    targetRect: spotRect,
                    radius: kRadiusMd + 4,
                  ),
                ),
              ),
            ),

            // ── Spotlight border pulse ──
            Positioned.fromRect(
              rect: spotRect,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kRadiusMd + 4),
                    border: Border.all(
                      color: step.accentColor.withValues(alpha: 0.6),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),

            // ── Tooltip card ──
            _buildTooltip(context, step, spotRect, screen, padding,
                isFirst, isLast),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltip(
    BuildContext context,
    TutorialStep step,
    Rect spotRect,
    Size screen,
    EdgeInsets safePadding,
    bool isFirst,
    bool isLast,
  ) {
    const tooltipMaxWidth = 340.0;
    const tooltipMargin = 16.0;

    // Determine whether to place tooltip below or above the spotlight
    final spaceBelow = screen.height - spotRect.bottom;
    final spaceAbove = spotRect.top;
    final placeBelow = spaceBelow > 220 || spaceBelow >= spaceAbove;

    final tooltipTop = placeBelow
        ? spotRect.bottom + 16
        : null;
    final tooltipBottom = placeBelow
        ? null
        : screen.height - spotRect.top + 16;

    // Horizontal: center on the spotlight, clamp within screen
    final spotCenterX = spotRect.center.dx;
    var tooltipLeft =
        (spotCenterX - tooltipMaxWidth / 2).clamp(tooltipMargin, screen.width - tooltipMaxWidth - tooltipMargin);

    return Positioned(
      top: tooltipTop,
      bottom: tooltipBottom,
      left: tooltipLeft,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kRadiusGlass),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: kBlurGlass, sigmaY: kBlurGlass),
          child: Container(
            width: tooltipMaxWidth,
            padding: const EdgeInsets.all(kS20),
            decoration: BoxDecoration(
              color: context.colors.bgElevated.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(kRadiusGlass),
              border: Border.all(color: context.colors.borderSubtle),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 30,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step indicator + icon
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: step.accentColor.withValues(alpha: 0.15),
                      ),
                      child: Icon(step.icon, size: 18, color: step.accentColor),
                    ),
                    const SizedBox(width: kS12),
                    Expanded(
                      child: Text(
                        step.title,
                        style: TextStyle(
                          fontFamily: kFontSerif,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: kS8, vertical: kS4),
                      decoration: BoxDecoration(
                        color: step.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(kRadiusPill),
                      ),
                      child: Text(
                        '${_currentStep + 1}/${widget.steps.length}',
                        style: TextStyle(
                          fontFamily: kFontSans,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: step.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: kS12),

                // Description
                Text(
                  step.description,
                  style: TextStyle(
                    fontFamily: kFontSans,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: context.colors.textSecondary,
                    height: 1.55,
                  ),
                ),

                const SizedBox(height: kS16),

                // Step dots + navigation
                Row(
                  children: [
                    // Dots
                    ...List.generate(widget.steps.length, (i) {
                      final active = i == _currentStep;
                      return AnimatedContainer(
                        duration: kDurationFast,
                        width: active ? 20 : 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(kRadiusFull),
                          color: active
                              ? step.accentColor
                              : context.colors.borderSubtle,
                        ),
                      );
                    }),

                    const Spacer(),

                    // Previous
                    if (!isFirst)
                      _TooltipButton(
                        label: 'Anterior',
                        onTap: _prev,
                        secondary: true,
                      ),

                    if (!isFirst) const SizedBox(width: kS6),

                    // Skip
                    if (!isLast)
                      _TooltipButton(
                        label: 'Ometre',
                        onTap: _dismiss,
                        secondary: true,
                      ),

                    if (!isLast) const SizedBox(width: kS6),

                    // Next / Done
                    _TooltipButton(
                      label: isLast ? 'Entesos!' : 'Següent',
                      onTap: _next,
                      accentColor: step.accentColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Spotlight painter — dark overlay with cutout hole
// ═══════════════════════════════════════════════════════════════════════════

class _SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final double radius;

  _SpotlightPainter({required this.targetRect, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;
    final holePath = Path()
      ..addRRect(RRect.fromRectAndRadius(targetRect, Radius.circular(radius)));
    final bgPath = Path()..addRect(fullRect);
    final combined = Path.combine(PathOperation.difference, bgPath, holePath);

    canvas.drawPath(
      combined,
      Paint()..color = const Color(0xAA000000),
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.targetRect != targetRect || old.radius != radius;
}

// ═══════════════════════════════════════════════════════════════════════════
// Tooltip button
// ═══════════════════════════════════════════════════════════════════════════

class _TooltipButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool secondary;
  final Color? accentColor;

  const _TooltipButton({
    required this.label,
    required this.onTap,
    this.secondary = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (secondary) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: kS6, vertical: kS4),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: kFontSans,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.colors.textTertiary,
              ),
            ),
          ),
        ),
      );
    }

    final bg = accentColor ?? (isDark ? const Color(0xFFF5F5F5) : context.colors.textPrimary);
    final fg = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: kS12, vertical: kS6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(kRadiusMd),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: kFontSans,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
