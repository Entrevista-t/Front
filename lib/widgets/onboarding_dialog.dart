import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart' show kFontSerif, kFontSans;

// ═══════════════════════════════════════════════════════════════════════════
// Slide data
// ═══════════════════════════════════════════════════════════════════════════

class _Slide {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final Color iconColor;

  const _Slide({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.iconColor,
  });
}

const _slides = [
  _Slide(
    id: 'welcome',
    title: "Benvingut/da a l'entrevista",
    description:
        "Estàs a punt de fer una entrevista simulada amb intel·ligència "
        "artificial. Se't mostrarà una pregunta, gravaràs la teva resposta "
        "en vídeo i rebràs un informe detallat amb puntuacions i consells "
        "per millorar.",
    icon: Icons.waving_hand_rounded,
    gradientColors: [Color(0xFFEAF2FF), Color(0xFFCDE2FF)],
    iconColor: Color(0xFF3B82F6),
  ),
  _Slide(
    id: 'setup',
    title: "Prepara't",
    description:
        "Assegura't que la càmera i el micròfon funcionen correctament. "
        "Situa't en un lloc ben il·luminat i centra't al marc de la càmera. "
        "El navegador et demanarà permisos d'accés — accepta'ls per continuar.",
    icon: Icons.videocam_rounded,
    gradientColors: [Color(0xFFE8FFF7), Color(0xFFCAF6E8)],
    iconColor: Color(0xFF14B8A6),
  ),
  _Slide(
    id: 'recording',
    title: "Durant l'entrevista",
    description:
        "Prem el botó de gravació per començar. Parla amb naturalitat "
        "durant aproximadament un minut. No surtis del marc de la càmera: "
        "l'anàlisi de contacte visual i expressió facial en depèn. Quan "
        "acabis, prem el botó per aturar i enviar.",
    icon: Icons.mic_rounded,
    gradientColors: [Color(0xFFFFF6E8), Color(0xFFFFE8C2)],
    iconColor: Color(0xFFF59E0B),
  ),
  _Slide(
    id: 'results',
    title: 'Resultats i feedback',
    description:
        "Un cop enviada la gravació, la nostra IA analitzarà la teva "
        "resposta: rellevància, coherència, riquesa lèxica, to emocional, "
        "contacte visual i molt més. Rebràs un informe PDF complet amb "
        "puntuacions, gràfics i consells personalitzats.",
    icon: Icons.insights_rounded,
    gradientColors: [Color(0xFFF2ECFF), Color(0xFFE1D4FF)],
    iconColor: Color(0xFF8B5CF6),
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
// Public API
// ═══════════════════════════════════════════════════════════════════════════

/// Shows the onboarding dialog as a modal overlay.
/// Returns when the user dismisses it.
Future<void> showOnboardingDialog(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Onboarding',
    barrierColor: Colors.black.withValues(alpha: 0.60),
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (context, anim, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
    pageBuilder: (context, _, __) => const _OnboardingDialog(),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Dialog widget
// ═══════════════════════════════════════════════════════════════════════════

class _OnboardingDialog extends StatefulWidget {
  const _OnboardingDialog();

  @override
  State<_OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<_OnboardingDialog> {
  final _controller = PageController();
  int _activeIndex = 0;

  bool get _isFirst => _activeIndex == 0;
  bool get _isLast => _activeIndex == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      Navigator.of(context).pop();
      return;
    }
    _controller.nextPage(
      duration: kDurationNormal,
      curve: Curves.easeInOut,
    );
  }

  void _prev() {
    _controller.previousPage(
      duration: kDurationNormal,
      curve: Curves.easeInOut,
    );
  }

  void _skip() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(kRadiusGlass),
              child: BackdropFilter(
                filter:
                    ImageFilter.blur(sigmaX: kBlurGlass, sigmaY: kBlurGlass),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colors.bgElevated,
                    borderRadius: BorderRadius.circular(kRadiusGlass),
                    border: Border.all(color: context.colors.borderSubtle),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x30000000),
                        blurRadius: 40,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Carousel ──────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            kS12, kS12, kS12, 0),
                        child: SizedBox(
                          height: 200,
                          child: PageView.builder(
                            controller: _controller,
                            itemCount: _slides.length,
                            onPageChanged: (i) =>
                                setState(() => _activeIndex = i),
                            itemBuilder: (_, i) =>
                                _SlideIllustration(slide: _slides[i]),
                          ),
                        ),
                      ),

                      // ── Dots ──────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.only(top: kS12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_slides.length, (i) {
                            final active = i == _activeIndex;
                            return GestureDetector(
                              onTap: () => _controller.animateToPage(
                                i,
                                duration: kDurationNormal,
                                curve: Curves.easeInOut,
                              ),
                              child: AnimatedContainer(
                                duration: kDurationFast,
                                curve: Curves.easeOut,
                                width: active ? 24 : 16,
                                height: 8,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 3),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(kRadiusFull),
                                  color: active
                                      ? context.colors.textPrimary
                                      : context.colors.borderSubtle,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      // ── Title + Description ───────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            kS20, kS16, kS20, 0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: Column(
                            key: ValueKey(_activeIndex),
                            children: [
                              Text(
                                _slides[_activeIndex].title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: kFontSerif,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: context.colors.textPrimary,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: kS8),
                              Text(
                                _slides[_activeIndex].description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: kFontSans,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: context.colors.textSecondary,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Buttons ───────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            kS16, kS24, kS16, kS16),
                        child: Row(
                          children: [
                            // Back button
                            if (!_isFirst)
                              _TextBtn(
                                label: 'Anterior',
                                onTap: _prev,
                              )
                            else
                              const SizedBox(width: 80),

                            const Spacer(),

                            // Skip
                            _TextBtn(
                              label: 'Ometre',
                              onTap: _skip,
                            ),

                            const SizedBox(width: kS8),

                            // Next / Start
                            _PrimaryBtn(
                              label: _isLast ? 'Comença' : 'Següent',
                              onTap: _next,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Slide illustration (gradient placeholder with icon)
// ═══════════════════════════════════════════════════════════════════════════

class _SlideIllustration extends StatelessWidget {
  final _Slide slide;
  const _SlideIllustration({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kRadiusMd),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: slide.gradientColors,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: slide.iconColor.withValues(alpha: 0.18),
                ),
                child: Icon(
                  slide.icon,
                  size: 36,
                  color: slide.iconColor,
                ),
              ),
              const SizedBox(height: kS12),
              Text(
                slide.title,
                style: TextStyle(
                  fontFamily: kFontSans,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: slide.iconColor.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Button helpers
// ═══════════════════════════════════════════════════════════════════════════

class _TextBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TextBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kS12, vertical: kS6),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: kFontSans,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.colors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryBtn({required this.label, required this.onTap});

  @override
  State<_PrimaryBtn> createState() => _PrimaryBtnState();
}

class _PrimaryBtnState extends State<_PrimaryBtn> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFFF5F5F5) : context.colors.textPrimary;
    final fg = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: kDurationFast,
          padding:
              const EdgeInsets.symmetric(horizontal: kS16, vertical: kS8),
          decoration: BoxDecoration(
            color: _hovering ? bg.withValues(alpha: 0.85) : bg,
            borderRadius: BorderRadius.circular(kRadiusMd),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: kFontSans,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
