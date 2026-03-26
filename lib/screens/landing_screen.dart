import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

// ── Floating particles background ──────────────────────────────────────────
class _ParticlesPainter extends CustomPainter {
  final double tick;
  final List<_Particle> particles;

  _ParticlesPainter(this.tick, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final x = (p.x * size.width + tick * p.dx * size.width) % size.width;
      final y = (p.y * size.height + tick * p.dy * size.height) % size.height;
      canvas.drawCircle(
        Offset(x, y),
        p.radius,
        Paint()..color = p.color.withValues(alpha: p.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter old) => true;
}

class _Particle {
  final double x, y, dx, dy, radius, opacity;
  final Color color;
  _Particle(this.x, this.y, this.dx, this.dy, this.radius, this.opacity, this.color);
}

// ── Scroll-triggered fade+slide widget ─────────────────────────────────────
class _ScrollReveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _ScrollReveal({required this.child, this.delay = Duration.zero});

  @override
  State<_ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<_ScrollReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _triggered = false;
  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to the ancestor scrollable's position
    final newPos = Scrollable.maybeOf(context)?.position;
    if (newPos != _scrollPosition) {
      _scrollPosition?.removeListener(_maybeReveal);
      _scrollPosition = newPos;
      _scrollPosition?.addListener(_maybeReveal);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeReveal());
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_maybeReveal);
    _ctrl.dispose();
    super.dispose();
  }

  void _maybeReveal() {
    if (_triggered || !mounted) return;
    final ro = context.findRenderObject();
    if (ro == null || !ro.attached) return;
    final box = ro as RenderBox;
    if (!box.hasSize) return;
    final offset = box.localToGlobal(Offset.zero);
    final screenH = MediaQuery.of(context).size.height;
    if (offset.dy < screenH + 80) {
      _triggered = true;
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = Curves.easeOut.transform(_ctrl.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
              offset: Offset(0, 24 * (1 - t)), child: child),
        );
      },
      child: widget.child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _particleCtrl;
  late final AnimationController _stagger;
  late final List<Animation<double>> _heroFades;
  late final List<Animation<Offset>> _heroSlides;
  late final List<_Particle> _particles;

  static const _heroItems = 4;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 30))
      ..repeat();
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

    final rng = Random(42);
    final colors = [kAccent, kAccentTeal, kAccentAmber, kAccentSky, kAccentRose];
    _particles = List.generate(28, (_) => _Particle(
      rng.nextDouble(), rng.nextDouble(),
      (rng.nextDouble() - 0.5) * 0.3, (rng.nextDouble() - 0.5) * 0.15,
      rng.nextDouble() * 1.8 + 0.6, rng.nextDouble() * 0.12 + 0.03,
      colors[rng.nextInt(colors.length)],
    ));
  }

  @override
  void dispose() {
    _pulse.dispose();
    _particleCtrl.dispose();
    _stagger.dispose();
    super.dispose();
  }

  Widget _heroAnim(int i, Widget child) => SlideTransition(
        position: _heroSlides[i],
        child: FadeTransition(opacity: _heroFades[i], child: child));

  // ── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Particles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) => CustomPaint(
                  painter: _ParticlesPainter(_particleCtrl.value, _particles)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildNavBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(children: [
                      _buildHero(context),
                      const SizedBox(height: 64),
                      _buildMetrics(context),
                      const SizedBox(height: 64),
                      _buildFeatures(context),
                      const SizedBox(height: 64),
                      _buildPdf(context),
                      const SizedBox(height: 64),
                      _buildCta(context),
                      const SizedBox(height: kS32),
                      _buildFooter(context),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── NAV BAR ──────────────────────────────────────────────────────────────
  Widget _buildNavBar(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: kPagePadding, vertical: 10),
          decoration: BoxDecoration(
            color: kBgSurface.withValues(alpha: 0.85),
            border: const Border(bottom: BorderSide(color: kBorderSubtle)),
          ),
          child: Row(children: [
            // Left buttons
            OutlinedButton(
              onPressed: () => context.go('/login'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  padding: const EdgeInsets.symmetric(horizontal: kS20)),
              child: const Text('Iniciar sessió'),
            ),
            const Spacer(),
            // Centered logo
            Image.asset('assets/images/logo_entrevistat.png',
                width: 36, height: 36, fit: BoxFit.contain),
            const Spacer(),
            // Right button
            ElevatedButton(
              onPressed: () => context.go('/login?mode=register'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  padding: const EdgeInsets.symmetric(horizontal: kS20)),
              child: const Text("Registra't"),
            ),
          ]),
        ),
      ),
    );
  }

  // ── HERO ─────────────────────────────────────────────────────────────────
  Widget _buildHero(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kPagePadding, 48, kPagePadding, kS16),
      child: Column(children: [
        _heroAnim(0, Text('Domina les teves\nentrevistes amb IA',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge)),
        const SizedBox(height: kS16),
        _heroAnim(1, Text(
            'Practica entrevistes simulades amb intel·ligència artificial.\n'
            'Anàlisi de veu, eye tracking i informes PDF detallats.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: kTextSecondary, height: 1.6))),
        const SizedBox(height: kS32),
        _heroAnim(2, Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => context.go('/login?mode=register'),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Comença ara'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, foregroundColor: kBgBase,
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: kS24)),
            ),
            const SizedBox(width: kS12),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: kS24)),
              child: const Text('Veure demo'),
            ),
          ],
        )),
        const SizedBox(height: 48),
        _heroAnim(3, _buildShowcase()),
      ]),
    );
  }

  // ── SHOWCASE ─────────────────────────────────────────────────────────────
  Widget _buildShowcase() {
    return Container(
      height: 300, width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 480),
      decoration: BoxDecoration(
        color: kBgSurface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        border: Border.all(color: kAccent.withValues(alpha: 0.15)),
      ),
      child: Stack(children: [
        Positioned.fill(child: ClipRRect(
          borderRadius: BorderRadius.circular(kRadiusLg),
          child: Container(decoration: BoxDecoration(
            gradient: RadialGradient(center: Alignment.center, radius: 0.7,
                colors: [kAccent.withValues(alpha: 0.06), kBgSurface]),
          )),
        )),
        Center(child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) {
            final o = 0.4 + 0.6 * _pulse.value;
            return Opacity(opacity: o, child: Stack(
              alignment: Alignment.center,
              children: [
                _ring(140, kAccent.withValues(alpha: 0.2)),
                _ring(90, kAccent.withValues(alpha: 0.5)),
                CircleAvatar(radius: 28,
                    backgroundColor: kAccent.withValues(alpha: 0.15),
                    child: const Icon(Icons.person, color: kAccent, size: 30)),
                _line(true), _line(false),
              ],
            ));
          },
        )),
        Positioned(top: kS16, left: kS16,
            child: _badge(Icons.visibility_outlined, 'Eye Tracking', kAccentTeal)),
        Positioned(top: kS16, right: kS16, child: _liveBadge()),
        Positioned(bottom: kS16, left: kS16,
            child: _badge(Icons.graphic_eq_rounded, 'Anàlisi de veu', kAccentAmber)),
        Positioned(bottom: kS16, right: kS16,
            child: _badge(Icons.picture_as_pdf_outlined, 'Informe PDF', kAccentRose)),
      ]),
    );
  }

  Widget _ring(double s, Color c) => Container(width: s, height: s,
      decoration: BoxDecoration(shape: BoxShape.circle,
          border: Border.all(color: c, width: 1.5)));

  Widget _line(bool h) => Container(
      width: h ? 110 : 1.5, height: h ? 1.5 : 110,
      color: kAccent.withValues(alpha: 0.4));

  Widget _badge(IconData icon, String label, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: kBgBase.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(kRadiusSm),
            border: Border.all(color: c.withValues(alpha: 0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: c, size: 13), const SizedBox(width: 5),
          Text(label, style: const TextStyle(
              color: kTextPrimary, fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
      );

  Widget _liveBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: kAccentTeal.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(kRadiusPill),
            border: Border.all(color: kAccentTeal.withValues(alpha: 0.35))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.circle, color: kAccentTeal, size: 7),
          const SizedBox(width: 6),
          Text('En viu', style: TextStyle(
              color: kAccentTeal, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      );

  // ── METRICS ──────────────────────────────────────────────────────────────
  Widget _buildMetrics(BuildContext context) {
    final videoMetrics = [
      _Metric('Presència en càmera', '96 %', Icons.person_search_outlined, kAccentTeal,
          "Detectem si el candidat es manté dins l'enquadrament durant tota l'entrevista."),
      _Metric('Contacte visual', '68 %', Icons.visibility_outlined, kAccentTeal,
          "Mesurem quan mantens la mirada cap a la càmera per transmetre seguretat."),
      _Metric('Alertes de desconnexió', '3', Icons.warning_amber_rounded, kAccentAmber,
          "Detecció en temps real de quan apartes la mirada: possible lectura de notes o distraccions."),
      _Metric('Calma i concentració', '82 %', Icons.self_improvement_rounded, kAccentSky,
          "Temps que el candidat es manté professional i serè sota pressió."),
      _Metric('Empatia i positivisme', '71 %', Icons.sentiment_satisfied_alt_rounded, kAccentTeal,
          "Temps mostrant actitud afable, somriures o recepció positiva. Mesura habilitats toves."),
      _Metric('Tensió detectada', '12 %', Icons.mood_bad_outlined, kAccentRose,
          "Pics d'estrès detectats: arrufar el front, rigidesa facial o signes de nerviosisme."),
      _Metric('Intensitat expressiva', '65 %', Icons.face_retouching_natural_rounded, kAccentAmber,
          "Quant esforç facial fa el candidat per comunicar-se i emfatitzar els punts clau."),
    ];

    final audioMetrics = [
      _Metric("Alineació amb la pregunta", '78 %', Icons.track_changes_rounded, kAccentSky,
          "Mesura si la resposta va directa al gra o si el candidat s'allunya del tema."),
      _Metric('Estructura del discurs', '70 %', Icons.account_tree_outlined, kAccentTeal,
          "Avalua si les frases segueixen un fil lògic ordenat (com el mètode STAR) o són caòtiques."),
      _Metric("Densitat d'informació", '63 %', Icons.compress_rounded, kAccentAmber,
          "Ratio de paraules amb valor real vs. paraules buides o redundants. Detecta qui parla molt però diu poc."),
      _Metric("Índex d'especificitat", '59 %', Icons.format_quote_rounded, kAccentRose,
          "Mesura si el candidat usa termes específics o abusa de pronoms vagues com 'vam fer allò'."),
      _Metric('Riquesa lèxica', '72 %', Icons.menu_book_rounded, kAccentSky,
          "Varietat del vocabulari i domini de la terminologia professional del sector."),
      _Metric('Seguretat i confiança', '66 %', Icons.mic_rounded, kAccentTeal,
          "Comptabilitza silencis incòmodes i muletilles de dubte. El millor detector de nerviosisme."),
      _Metric('Ritme de comunicació', '142 ppm', Icons.speed_rounded, kAccentAmber,
          "Paraules per minut. Massa ràpid denota ansietat, massa lent pot avorrir l'entrevistador."),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
      child: Column(children: [
        _ScrollReveal(child: Column(children: [
          Text("Mètriques que t'importen",
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: kS8),
          Text('Cada sessió analitza el teu rendiment en múltiples dimensions.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: kTextSecondary),
              textAlign: TextAlign.center),
        ])),

        const SizedBox(height: kS32),

        // Video section
        _ScrollReveal(child: _metricSectionLabel(context, Icons.videocam_outlined, 'Anàlisi de vídeo')),
        const SizedBox(height: kS16),
        _buildMetricGrid(context, videoMetrics),

        const SizedBox(height: kS32),

        // Audio section
        _ScrollReveal(child: _metricSectionLabel(context, Icons.graphic_eq_rounded, 'Anàlisi de veu i contingut')),
        const SizedBox(height: kS16),
        _buildMetricGrid(context, audioMetrics),
      ]),
    );
  }

  Widget _metricSectionLabel(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: kAccent, size: 18),
        const SizedBox(width: kS8),
        Text(label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: kAccent,
            )),
      ],
    );
  }

  Widget _buildMetricGrid(BuildContext context, List<_Metric> items) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth > 600;
      final cards = items.asMap().entries.map((e) => _ScrollReveal(
          delay: Duration(milliseconds: 80 * e.key),
          child: _metricCard(context, e.value, constraints.maxWidth))).toList();
      if (wide) {
        final halfW = (constraints.maxWidth - kS16) / 2;
        final isOdd = cards.length.isOdd;
        return Wrap(
          spacing: kS16,
          runSpacing: kS16,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: cards.asMap().entries.map((e) => SizedBox(
              width: (isOdd && e.key == cards.length - 1)
                  ? constraints.maxWidth
                  : halfW,
              child: e.value)).toList(),
        );
      }
      return Column(children: cards);
    });
  }

  Widget _metricCard(BuildContext context, _Metric m, [double? parentWidth]) => Padding(
        padding: parentWidth != null && parentWidth > 600
            ? EdgeInsets.zero
            : const EdgeInsets.only(bottom: kS16),
        child: Container(
          decoration: BoxDecoration(
              color: kBgSurface,
              borderRadius: BorderRadius.circular(kRadiusMd),
              border: Border.all(color: kBorderSubtle)),
          clipBehavior: Clip.antiAlias,
          child: Row(children: [
            Container(width: 3, height: 90, color: m.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(kS20),
                child: Row(children: [
                  Container(width: 48, height: 48,
                      decoration: BoxDecoration(
                          color: m.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(kRadiusMd)),
                      child: Icon(m.icon, color: m.color, size: 24)),
                  const SizedBox(width: kS16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(m.label, style: Theme.of(context).textTheme.titleSmall),
                        const Spacer(),
                        Text(m.value, style: TextStyle(
                            color: m.color, fontWeight: FontWeight.w700, fontSize: 16)),
                      ]),
                      const SizedBox(height: kS4),
                      Text(m.desc, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  )),
                ]),
              ),
            ),
          ]),
        ),
      );

  // ── FEATURES ─────────────────────────────────────────────────────────────
  Widget _buildFeatures(BuildContext context) {
    final items = [
      _Feat(Icons.smart_toy_outlined, 'Entrevistes amb IA',
          "L'IA fa d'entrevistador i adapta les preguntes al teu nivell i perfil professional.", kAccentTeal),
      _Feat(Icons.bar_chart_rounded, 'Anàlisi en temps real',
          'Contacte visual, velocitat de parla, paraules falca i to de veu analitzats mentre parles.', kAccentAmber),
      _Feat(Icons.category_outlined, 'Múltiples categories',
          'Software, màrqueting, gestió de projectes, disseny i moltes més especialitats.', kAccentRose),
      _Feat(Icons.trending_up_rounded, 'Seguiment del progrés',
          'Compara sessions anteriors, veu la teva evolució i estableix objectius de millora.', kAccentSky),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
      child: Column(children: [
        _ScrollReveal(child: Column(children: [
          Text('Funcionalitats',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: kS8),
          Text('Tot el que necessites per dominar les entrevistes.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: kTextSecondary),
              textAlign: TextAlign.center),
        ])),
        const SizedBox(height: kS32),
        LayoutBuilder(builder: (context, constraints) {
          final cards = items.asMap().entries.map((e) => _ScrollReveal(
              delay: Duration(milliseconds: 80 * e.key),
              child: _featCard(context, e.value, constraints.maxWidth))).toList();
          if (constraints.maxWidth > 600) {
            return Wrap(
              spacing: kS16,
              runSpacing: kS16,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: cards.map((c) => SizedBox(
                  width: (constraints.maxWidth - kS16) / 2,
                  child: c)).toList(),
            );
          }
          return Column(children: cards);
        }),
      ]),
    );
  }

  Widget _featCard(BuildContext context, _Feat f, [double? parentWidth]) => Padding(
        padding: parentWidth != null && parentWidth > 600
            ? EdgeInsets.zero
            : const EdgeInsets.only(bottom: kS16),
        child: Container(
          decoration: BoxDecoration(
              color: kBgSurface,
              borderRadius: BorderRadius.circular(kRadiusMd),
              border: Border.all(color: kBorderSubtle)),
          clipBehavior: Clip.antiAlias,
          child: Row(children: [
            Container(width: 3, height: 90, color: f.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(kS20),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 44, height: 44,
                      decoration: BoxDecoration(
                          color: f.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(kRadiusMd)),
                      child: Icon(f.icon, color: f.color, size: 22)),
                  const SizedBox(width: kS16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.title, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: kS4),
                      Text(f.desc, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  )),
                ]),
              ),
            ),
          ]),
        ),
      );

  // ── PDF SECTION ──────────────────────────────────────────────────────────
  Widget _buildPdf(BuildContext context) => _ScrollReveal(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(kS32),
            decoration: BoxDecoration(
              color: kBgSurface,
              borderRadius: BorderRadius.circular(kRadiusLg),
              border: Border.all(color: kAccentRose.withValues(alpha: 0.2)),
              gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [kAccentRose.withValues(alpha: 0.04), kBgSurface]),
            ),
            child: Column(children: [
              Container(width: 56, height: 56,
                  decoration: BoxDecoration(
                      color: kAccentRose.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(kRadiusMd)),
                  child: const Icon(Icons.picture_as_pdf_outlined,
                      color: kAccentRose, size: 28)),
              const SizedBox(height: kS20),
              Text('Informe PDF detallat',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: kS12),
              Text(
                'Al final de cada sessió, descarrega un informe complet amb:\n'
                'puntuació global, anàlisi de fluïdesa, contingut, estructura,\n'
                'confiança, punts forts i recomanacions personalitzades.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: kTextSecondary, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: kS24),
              Wrap(
                spacing: kS8, runSpacing: kS8,
                alignment: WrapAlignment.center,
                children: [
                  _pdfChip(Icons.score_rounded, 'Puntuació'),
                  _pdfChip(Icons.lightbulb_outline, 'Recomanacions'),
                  _pdfChip(Icons.compare_arrows_rounded, 'Comparativa'),
                ],
              ),
            ]),
          ),
        ),
      );

  Widget _pdfChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: kAccentRose.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(kRadiusPill),
            border: Border.all(color: kAccentRose.withValues(alpha: 0.2))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: kAccentRose, size: 14),
          const SizedBox(width: kS4),
          Text(label, style: const TextStyle(
              color: kAccentRose, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      );

  // ── CTA BANNER ───────────────────────────────────────────────────────────
  Widget _buildCta(BuildContext context) => _ScrollReveal(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: kS32, horizontal: kS24),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kRadiusLg),
                gradient: LinearGradient(
                    colors: [kAccent, kAccent.withValues(alpha: 0.7)])),
            child: Column(children: [
              Text('Preparat per la teva\npròxima entrevista?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white),
                  textAlign: TextAlign.center),
              const SizedBox(height: kS12),
              Text("Registra't gratuïtament i comença a practicar avui.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8)),
                  textAlign: TextAlign.center),
              const SizedBox(height: kS24),
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) {
                  final blur = 8.0 + 12.0 * _pulse.value;
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(kRadiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.15),
                          blurRadius: blur,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: ElevatedButton(
                  onPressed: () => context.go('/login?mode=register'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, foregroundColor: kAccent,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: kS32)),
                  child: const Text('Comença ara'),
                ),
              ),
            ]),
          ),
        ),
      );

  // ── FOOTER ───────────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: kPagePadding, vertical: kS16),
        decoration: const BoxDecoration(
          color: kBgSurface,
          border: Border(top: BorderSide(color: kBorderSubtle)),
        ),
        child: Row(children: [
          Image.asset('assets/images/logo_entrevistat.png',
              width: 24, height: 24, fit: BoxFit.contain),
          const SizedBox(width: kS8),
          Text("Entrevista't",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: kTextSecondary, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text("© ${DateTime.now().year} Entrevista't",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: kTextDisabled)),
        ]),
      );
}

// ── Data classes ───────────────────────────────────────────────────────────
class _Feat {
  final IconData icon; final String title, desc; final Color color;
  const _Feat(this.icon, this.title, this.desc, this.color);
}

class _Metric {
  final String label, value, desc; final IconData icon; final Color color;
  const _Metric(this.label, this.value, this.icon, this.color, this.desc);
}
