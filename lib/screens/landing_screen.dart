import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart' show kFontSerif, kFontSans;
import '../widgets/dot_grid_background.dart';
import '../widgets/floating_glass_card.dart';

// ═══════════════════════════════════════════════════════════════════════════
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _stagger;
  late final List<Animation<double>> _heroFades;
  late final List<Animation<Offset>> _heroSlides;

  static const _heroItems = 4;

  // Testimonial data for floating cards
  static const _reviews = [
    _Review('Anna M.', "M'ha ajudat molt a preparar l'entrevista de Google!",
        5, kAccentTeal),
    _Review('Marc R.', "L'anàlisi de veu és increïble. Mai havia vist res igual.",
        5, kAccentSky),
    _Review('Laia P.', 'Vaig aconseguir la feina gràcies a practicar aquí.',
        5, kAccentAmber),
    _Review('Jordi S.', 'El feedback en temps real és molt útil per millorar.',
        4, kAccentRose),
    _Review('Núria V.', "L'informe PDF m'ajuda a veure el meu progrés real.",
        5, kAccentTeal),
    _Review('Marta G.', 'La millor eina de preparació que he provat mai.',
        5, kAccentSky),
  ];

  // Avatar indices matching gender: F=4,6,7,9  M=5,8
  static const _reviewAvatars = [4, 5, 6, 8, 7, 9];

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..forward();

    _heroFades = List.generate(_heroItems, (i) {
      final s = (i * 0.15).clamp(0.0, 0.7);
      final e = (s + 0.35).clamp(0.0, 1.0);
      return CurvedAnimation(
          parent: _stagger, curve: Interval(s, e, curve: Curves.easeOut));
    });
    _heroSlides = List.generate(_heroItems, (i) {
      final s = (i * 0.15).clamp(0.0, 0.7);
      final e = (s + 0.35).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _stagger, curve: Interval(s, e, curve: Curves.easeOut)));
    });
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  Widget _heroAnim(int i, Widget child) => SlideTransition(
        position: _heroSlides[i],
        child: FadeTransition(opacity: _heroFades[i], child: child));

  // ── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    return Scaffold(
      body: DotGridBackground(
        child: Stack(
          children: [
            // Layer 1: Decorative oversized serif text
            if (isWide) ...[
              Positioned(
                top: size.height * 0.12,
                left: -40,
                child: _decorativeText('Entrevista'),
              ),
              Positioned(
                bottom: size.height * 0.10,
                right: -30,
                child: _decorativeText('Feedback'),
              ),
            ],

            // Layer 2: Floating glass review cards
            ..._buildFloatingCards(size, isWide),

            // Layer 3: Main content
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: kPagePadding, vertical: kS32),
                          child: _buildHero(context),
                        ),
                      ),
                    ),
                  ),
                  _buildFooter(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── DECORATIVE BACKGROUND TEXT ──────────────────────────────────────────
  Widget _decorativeText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: kFontSerif,
        fontSize: 128,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.normal,
        color: context.colors.textPrimary.withValues(alpha: 0.03),
        height: 1,
      ),
    );
  }

  // ── FLOATING REVIEW CARDS ──────────────────────────────────────────────
  List<Widget> _buildFloatingCards(Size screen, bool isWide) {
    if (!isWide) return [];

    // Card positions scattered around the periphery
    final positions = [
      // Top-left
      Offset(screen.width * 0.02, screen.height * 0.15),
      // Top-right
      Offset(screen.width * 0.72, screen.height * 0.10),
      // Left middle
      Offset(screen.width * 0.01, screen.height * 0.52),
      // Right middle
      Offset(screen.width * 0.74, screen.height * 0.48),
      // Bottom-left
      Offset(screen.width * 0.04, screen.height * 0.78),
      // Bottom-right
      Offset(screen.width * 0.70, screen.height * 0.76),
    ];

    final widths = [260.0, 280.0, 250.0, 290.0, 270.0, 260.0];
    final opacities = [0.50, 0.60, 0.45, 0.55, 0.40, 0.65];

    return List.generate(_reviews.length, (i) {
      final review = _reviews[i];
      final pos = positions[i];
      return Positioned(
        left: pos.dx,
        top: pos.dy,
        child: FloatingGlassCard(
          width: widths[i],
          delay: Duration(milliseconds: 800 + i * 600),
          opacity: opacities[i],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: review.color.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/avatar_${_reviewAvatars[i]}.png',
                        width: 28, height: 28,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(review.name, style: TextStyle(
                    fontFamily: kFontSans, fontSize: 12,
                    fontWeight: FontWeight.w600, color: context.colors.textPrimary,
                  )),
                ],
              ),
              const SizedBox(height: 8),
              Text(review.text, style: TextStyle(
                fontFamily: kFontSans, fontSize: 13,
                color: context.colors.textSecondary, height: 1.4,
              )),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (s) => Icon(
                  s < review.stars ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 14,
                  color: s < review.stars
                      ? const Color(0xFFF59E0B)
                      : context.colors.borderSubtle,
                )),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ── HERO ─────────────────────────────────────────────────────────────────
  Widget _buildHero(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Column(children: [
        // App name in large Gambetta serif
        _heroAnim(0, Text(
          "Entrevista't",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kFontSerif,
            fontSize: 72,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.normal,
            color: context.colors.textPrimary,
            letterSpacing: -1,
            height: 1.05,
          ),
        )),
        const SizedBox(height: kS16),
        _heroAnim(1, ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 512),
          child: Text(
            'Practica entrevistes simulades amb intel·ligència artificial. '
            'Anàlisi de veu, eye tracking i informes PDF detallats.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kFontSans,
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: context.colors.textSecondary,
              height: 1.6,
            ),
          ),
        )),
        const SizedBox(height: kS24),
        _heroAnim(1, const _MetricsMarquee()),
        const SizedBox(height: kS32),
        _heroAnim(2, Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Primary CTA with hover glow
            _PremiumButton(
              onPressed: () => context.go('/login?mode=register'),
              label: 'Comença ara',
              icon: Icons.play_arrow_rounded,
            ),
          ],
        )),
        const SizedBox(height: kS16),
        _heroAnim(2, GestureDetector(
          onTap: () => context.go('/login'),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontFamily: kFontSans, fontSize: 13,
                  color: context.colors.textTertiary),
                children: [
                  const TextSpan(text: 'Ja tens compte? '),
                  TextSpan(text: 'Inicia sessió',
                    style: TextStyle(
                      color: kAccent, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        )),
        const SizedBox(height: kS32),
        _heroAnim(3, _buildTrustSection()),
      ]),
    );
  }

  // ── TRUST SECTION ───────────────────────────────────────────────────────
  Widget _buildTrustSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 132, height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ...List.generate(3, (i) {
                final colors = [kAccentTeal, kAccentSky, kAccentAmber];
                return Positioned(
                  left: i * 26.0,
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors[i].withValues(alpha: 0.15),
                      border: Border.all(color: context.colors.bgBase, width: 3),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/avatar_${i + 1}.png',
                        width: 34, height: 34,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              }),
              Positioned(
                left: 2 * 26.0 + 28,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colors.bgBase,
                    border: Border.all(color: context.colors.borderSubtle, width: 2),
                  ),
                  child: Center(
                    child: Text('+12k', style: TextStyle(
                      fontFamily: kFontSans,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textSecondary,
                    )),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text.rich(
          TextSpan(
            style: TextStyle(fontFamily: kFontSans, fontSize: 13, color: context.colors.textTertiary),
            children: [
              const TextSpan(text: 'Uneix-te a '),
              TextSpan(text: '12.000+', style: TextStyle(
                fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
              const TextSpan(text: ' usuaris actius'),
            ],
          ),
        ),
      ],
    );
  }

  // ── FOOTER ───────────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: kPagePadding, vertical: kS16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _footerLink('POLÍTICA DE PRIVACITAT'),
        _footerDot(),
        _footerLink('SUPORT'),
        _footerDot(),
        _footerLink('GITHUB'),
      ],
    ),
  );

  Widget _footerLink(String text) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: () {},
      child: Text(
        text,
        style: TextStyle(
          fontFamily: kFontSans,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: context.colors.textTertiary,
          letterSpacing: 2.0,
        ),
      ),
    ),
  );

  Widget _footerDot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Container(
      width: 4, height: 4,
      decoration: BoxDecoration(
        color: context.colors.borderSubtle,
        shape: BoxShape.circle,
      ),
    ),
  );
}

// ── Premium CTA button with hover glow ──────────────────────────────────
class _PremiumButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  const _PremiumButton({
    required this.onPressed,
    required this.label,
    required this.icon,
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: kDurationFast,
          curve: kCurveHover,
          transform: Matrix4.identity()..scale(_hovering ? 1.02 : 1.0),
          transformAlignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background glow (visible on hover)
              Positioned(
                top: -2, left: -2, right: -2, bottom: -2,
                child: AnimatedOpacity(
                  opacity: _hovering ? 1.0 : 0.0,
                  duration: kDurationFast,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(kRadiusFull),
                      gradient: context.colors.gradientCtaGlow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(kRadiusFull),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
              // Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: _hovering ? Colors.black : context.colors.textPrimary,
                  borderRadius: BorderRadius.circular(kRadiusFull),
                  boxShadow: _hovering
                      ? [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 50, offset: const Offset(0, 25),
                        )]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1A1A1A)
                          : Colors.white,
                      size: 18),
                    const SizedBox(width: 12),
                    Text(widget.label, style: TextStyle(
                      fontFamily: kFontSans,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1A1A1A)
                          : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Metrics marquee ──────────────────────────────────────────────────────
class _MetricsMarquee extends StatefulWidget {
  const _MetricsMarquee();

  @override
  State<_MetricsMarquee> createState() => _MetricsMarqueeState();
}

class _MetricsMarqueeState extends State<_MetricsMarquee>
    with SingleTickerProviderStateMixin {
  static const _metrics = [
    ('🎯', 'Rellevància de resposta'),
    ('🧠', 'Coherència del discurs'),
    ('📊', 'Densitat d\'informació'),
    ('🔍', 'Índex d\'especificitat'),
    ('📚', 'Riquesa lèxica'),
    ('💪', 'Índex de confiança'),
    ('🗣️', 'Ritme comunicatiu'),
    ('😊', 'Distribució emocional'),
    ('🎭', 'Emoció dominant'),
    ('⚖️', 'Estabilitat emocional'),
  ];

  static const _chipHPad = 14.0;
  static const _chipGap = 12.0;
  static const _emojiSize = 13.0;
  static const _textSize = 12.0;
  static const _emojiGap = 6.0;

  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<Widget> _buildChips(BuildContext context) {
    return _metrics.map((m) {
      return Container(
        margin: const EdgeInsets.only(right: _chipGap),
        padding: const EdgeInsets.symmetric(horizontal: _chipHPad, vertical: 6),
        decoration: BoxDecoration(
          color: context.colors.borderSubtle.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(kRadiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(m.$1, style: const TextStyle(fontSize: _emojiSize)),
            const SizedBox(width: _emojiGap),
            Text(m.$2, style: TextStyle(
              fontFamily: kFontSans,
              fontSize: _textSize,
              fontWeight: FontWeight.w500,
              color: context.colors.textSecondary,
            )),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final chips = _buildChips(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: ClipRect(
        child: SizedBox(
          height: 36,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) {
                  return _MarqueeContent(
                    progress: _ctrl.value,
                    chips: chips,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MarqueeContent extends StatelessWidget {
  const _MarqueeContent({
    required this.progress,
    required this.chips,
  });

  final double progress;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    return CustomSingleChildLayout(
      delegate: _MarqueeLayoutDelegate(progress),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [...chips, ...chips],
      ),
    );
  }
}

class _MarqueeLayoutDelegate extends SingleChildLayoutDelegate {
  _MarqueeLayoutDelegate(this.progress);
  final double progress;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      const BoxConstraints();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final halfWidth = childSize.width / 2;
    return Offset(-progress * halfWidth, 0);
  }

  @override
  bool shouldRelayout(_MarqueeLayoutDelegate old) =>
      old.progress != progress;
}

// ── Data class ───────────────────────────────────────────────────────────
class _Review {
  final String name, text;
  final int stars;
  final Color color;
  const _Review(this.name, this.text, this.stars, this.color);
}
