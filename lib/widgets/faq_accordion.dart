import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart' show kFontSerif, kFontSans;

// ═══════════════════════════════════════════════════════════════════════════
// FAQ data
// ═══════════════════════════════════════════════════════════════════════════

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem(this.question, this.answer);
}

const _faqs = [
  _FaqItem(
    "Què és Entrevista't i com funciona?",
    "Entrevista't és una plataforma que et permet practicar entrevistes de "
        "feina simulades amb intel·ligència artificial. Tries una categoria "
        "professional, respons preguntes cronometrades davant la càmera, i reps "
        "un informe detallat amb puntuacions i recomanacions per millorar.",
  ),
  _FaqItem(
    "Quines categories d'entrevista hi ha disponibles?",
    "Oferim categories adaptades a diferents sectors professionals: tecnologia, "
        "màrqueting, sanitat, educació, finances i moltes més. El catàleg es va "
        "ampliant regularment amb noves especialitats.",
  ),
  _FaqItem(
    "Necessito una càmera per utilitzar la plataforma?",
    "Sí, cal una càmera web o la càmera del mòbil. L'anàlisi visual (eye "
        "tracking i expressió facial) és una part clau de l'avaluació. "
        "Assegura't de donar permisos d'accés a la càmera al navegador.",
  ),
  _FaqItem(
    "Com s'avaluen les meves respostes?",
    "La nostra IA analitza múltiples dimensions: rellevància de la resposta, "
        "coherència del discurs, riquesa lèxica, to emocional, contacte visual "
        "i ritme comunicatiu. Cada mètrica rep una puntuació individual.",
  ),
  _FaqItem(
    "Què inclou l'informe PDF?",
    "L'informe PDF conté les puntuacions de cada mètrica, gràfics de "
        "rendiment, la transcripció de les teves respostes, l'anàlisi emocional "
        "i consells personalitzats per millorar en futures entrevistes.",
  ),
  _FaqItem(
    "Les meves dades i gravacions són segures?",
    "Absolutament. Les gravacions es processen en temps real i no "
        "s'emmagatzemen permanentment. Seguim estrictament la normativa de "
        "protecció de dades (RGPD) i mai compartim informació amb tercers.",
  ),
  _FaqItem(
    "La plataforma és gratuïta?",
    "Pots començar a practicar de forma gratuïta amb accés a les "
        "funcionalitats bàsiques. Per obtenir informes avançats i anàlisis més "
        "detallades, oferim plans premium adaptats a les teves necessitats.",
  ),
  _FaqItem(
    "Puc repetir una entrevista per millorar?",
    "Sí! Pots repetir qualsevol entrevista tantes vegades com vulguis. Cada "
        "sessió genera un informe nou, cosa que et permet comparar el teu "
        "progrés al llarg del temps.",
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
// FAQ Accordion Section
// ═══════════════════════════════════════════════════════════════════════════

/// An animated FAQ accordion section styled with the app's glassmorphism
/// design system. Intended to be embedded in the landing page.
class FaqAccordionSection extends StatefulWidget {
  const FaqAccordionSection({super.key});

  @override
  State<FaqAccordionSection> createState() => _FaqAccordionSectionState();
}

class _FaqAccordionSectionState extends State<FaqAccordionSection>
    with TickerProviderStateMixin {
  int? _openIndex = 0;

  // Stagger entrance
  late final AnimationController _stagger;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  // +2 for header and bottom CTA
  static final _totalItems = _faqs.length + 2;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnims = List.generate(_totalItems, (i) {
      final s = (i * 0.08).clamp(0.0, 0.75);
      final e = (s + 0.25).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _stagger,
        curve: Interval(s, e, curve: Curves.easeOut),
      );
    });

    _slideAnims = List.generate(_totalItems, (i) {
      final s = (i * 0.08).clamp(0.0, 0.75);
      final e = (s + 0.25).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
          .animate(CurvedAnimation(
        parent: _stagger,
        curve: Interval(s, e, curve: Curves.easeOut),
      ));
    });
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  /// Starts the entrance animation. Called externally when the section
  /// scrolls into view, or immediately if already visible.
  void playEntrance() {
    if (!_stagger.isAnimating && _stagger.value == 0) {
      _stagger.forward();
    }
  }

  Widget _anim(int i, Widget child) => SlideTransition(
        position: _slideAnims[i],
        child: FadeTransition(opacity: _fadeAnims[i], child: child),
      );

  @override
  Widget build(BuildContext context) {
    // Trigger entrance when built (will be refined with visibility check)
    WidgetsBinding.instance.addPostFrameCallback((_) => playEntrance());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            _anim(
              0,
              Column(
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kAccent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(kRadiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.help_outline_rounded,
                            size: 14, color: kAccent),
                        const SizedBox(width: 6),
                        Text(
                          'FAQ',
                          style: TextStyle(
                            fontFamily: kFontSans,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kAccent,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: kS16),
                  Text(
                    'Preguntes freqüents',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: kFontSerif,
                      fontSize: 36,
                      fontWeight: FontWeight.w500,
                      color: context.colors.textPrimary,
                      letterSpacing: -0.3,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: kS12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Text(
                      'Tens un dubte? Aquí trobaràs les respostes més habituals. '
                      "Si no trobes el que busques, contacta'ns.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: kFontSans,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: context.colors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: kS32),
                ],
              ),
            ),

            // ── Accordion items ─────────────────────────────────────
            ...List.generate(_faqs.length, (i) {
              final faq = _faqs[i];
              final isOpen = _openIndex == i;
              return _anim(
                i + 1,
                Padding(
                  padding: const EdgeInsets.only(bottom: kS12),
                  child: _FaqCard(
                    question: faq.question,
                    answer: faq.answer,
                    isOpen: isOpen,
                    onTap: () =>
                        setState(() => _openIndex = isOpen ? null : i),
                  ),
                ),
              );
            }),

            const SizedBox(height: kS24),

            // ── Bottom CTA ──────────────────────────────────────────
            _anim(
              _totalItems - 1,
              _BottomCtaCard(),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Individual FAQ card with animated expand/collapse
// ═══════════════════════════════════════════════════════════════════════════

class _FaqCard extends StatefulWidget {
  final String question;
  final String answer;
  final bool isOpen;
  final VoidCallback onTap;

  const _FaqCard({
    required this.question,
    required this.answer,
    required this.isOpen,
    required this.onTap,
  });

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expandCtrl;
  late final Animation<double> _expandAnim;
  late final Animation<double> _chevronAnim;

  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: kDurationNormal,
    );
    _expandAnim = CurvedAnimation(
      parent: _expandCtrl,
      curve: Curves.easeInOut,
    );
    _chevronAnim = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _expandCtrl, curve: Curves.easeInOut),
    );
    if (widget.isOpen) _expandCtrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_FaqCard old) {
    super.didUpdateWidget(old);
    if (widget.isOpen != old.isOpen) {
      widget.isOpen ? _expandCtrl.forward() : _expandCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _hovering || widget.isOpen
        ? kAccent.withValues(alpha: 0.35)
        : context.colors.borderSubtle;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: kDurationFast,
          curve: kCurveHover,
          decoration: BoxDecoration(
            color: context.colors.bgSurface,
            borderRadius: BorderRadius.circular(kRadiusMd),
            border: Border.all(color: borderColor),
            boxShadow: _hovering ? kShadowMd : kShadowSm,
          ),
          child: Column(
            children: [
              // Question row
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: kS20, vertical: kS16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.question,
                        style: TextStyle(
                          fontFamily: kFontSans,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: kS12),
                    AnimatedBuilder(
                      animation: _chevronAnim,
                      builder: (_, child) => Transform.rotate(
                        angle: _chevronAnim.value,
                        child: child,
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: context.colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              // Answer (animated)
              SizeTransition(
                sizeFactor: _expandAnim,
                axisAlignment: -1.0,
                child: Column(
                  children: [
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: context.colors.borderSubtle,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          kS20, kS16, kS20, kS20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.answer,
                          style: TextStyle(
                            fontFamily: kFontSans,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: context.colors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
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

// ═══════════════════════════════════════════════════════════════════════════
// Bottom CTA card
// ═══════════════════════════════════════════════════════════════════════════

class _BottomCtaCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(kRadiusGlass),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: kBlurGlass, sigmaY: kBlurGlass),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: kS24, vertical: kS32),
          decoration: BoxDecoration(
            color: context.colors.glassBg,
            borderRadius: BorderRadius.circular(kRadiusGlass),
            border: Border.all(color: context.colors.glassBorder),
            boxShadow: kShadowGlass,
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kAccent.withValues(alpha: 0.10),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: kAccent,
                  size: 24,
                ),
              ),
              const SizedBox(height: kS16),
              Text(
                'Encara tens dubtes?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: kFontSerif,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: context.colors.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: kS8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Text(
                  "El nostre equip és aquí per ajudar-te. Contacta'ns i "
                  "et respondrem el més aviat possible.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: kFontSans,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: context.colors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: kS24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.email_outlined, size: 18),
                    label: const Text("Contacta'ns"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(160, 48),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
