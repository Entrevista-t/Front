import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _green = Color(0xFF00D4A1);
const _bgDark = Color(0xFF0F1117);
const _cardDark = Color(0xFF1A1E2E);
const _textLight = Color(0xFFE8EAF0);
const _textMuted = Color(0xFF7B8099);

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildNavBar(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHero(context),
                    _buildFeaturesRow(),
                    _buildBottomFeatures(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── NAV BAR ──────────────────────────────────────────────────────────────
  Widget _buildNavBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: _cardDark,
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Image.asset(
                'assets/images/logo_entrevistat.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              const Text("Entrevista't",
                  style: TextStyle(color: _textLight, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Spacer(),
          // Nav links (only on wider screens)
          if (MediaQuery.of(context).size.width > 600) ...[
            _navLink('Home'),
            _navLink('Entrevistes'),
            _navLink('Informes'),
            const SizedBox(width: 8),
          ],
          // CTA buttons
          OutlinedButton(
            onPressed: () => context.go('/login'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _green,
              side: const BorderSide(color: _green),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Iniciar sessió', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => context.go('/login?mode=register'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: _bgDark,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Registra\'t', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _navLink(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(label, style: const TextStyle(color: _textMuted, fontSize: 14)),
    );
  }

  // ── HERO ─────────────────────────────────────────────────────────────────
  Widget _buildHero(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      child: Column(
        children: [
          // Title
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.2),
              children: [
                TextSpan(text: 'Master your interviews\nwith ', style: TextStyle(color: _textLight)),
                TextSpan(text: 'AI', style: TextStyle(color: _green)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Practica entrevistes simulades amb intel·ligència artificial.\nAnàlisi de veu, eye tracking i informes PDF detallats.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textMuted, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => context.go('/login?mode=register'),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Comença ara', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: _bgDark,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 14),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textLight,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Veure demo'),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Central showcase
          isWide ? _buildShowcaseWide() : _buildShowcaseMobile(),
        ],
      ),
    );
  }

  Widget _buildShowcaseWide() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _buildLeftCard()),
            const SizedBox(width: 16),
            Expanded(flex: 3, child: _buildCentralCard()),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildRightPanel()),
          ],
        ),
        const SizedBox(height: 16),
        _buildShowcaseBottomRow(),
      ],
    );
  }

  Widget _buildShowcaseMobile() {
    return Column(
      children: [
        _buildCentralCard(),
        const SizedBox(height: 16),
        _buildRightPanel(),
        const SizedBox(height: 16),
        _buildShowcaseBottomRow(),
      ],
    );
  }

  Widget _buildLeftCard() {
    return Container(
      height: 340,
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _featureBadge(Icons.smart_toy_outlined, 'IA Activa'),
          const Spacer(),
          Center(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) {
                final glow = 0.2 + 0.4 * _pulse.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _green.withValues(alpha: glow),
                          width: 1.5,
                        ),
                      ),
                    ),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: _green.withValues(alpha: 0.12),
                      child: const Icon(Icons.person, color: _green, size: 44),
                    ),
                  ],
                );
              },
            ),
          ),
          const Spacer(),
          const Text(
            'Entrevistes\nde Software',
            style: TextStyle(color: _textLight, fontWeight: FontWeight.bold, fontSize: 15, height: 1.3),
          ),
          const SizedBox(height: 8),
          _featureBadge(Icons.visibility_outlined, 'Eye Tracking'),
        ],
      ),
    );
  }

  Widget _buildShowcaseBottomRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _green.withValues(alpha: 0.2),
                child: const Text('ET', style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              const SizedBox(width: 6),
              CircleAvatar(
                radius: 18,
                backgroundColor: _green.withValues(alpha: 0.1),
                child: const Icon(Icons.person_outline, color: _green, size: 18),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Icons.mic_none_rounded,
                  Icons.visibility_outlined,
                  Icons.analytics_outlined,
                  Icons.picture_as_pdf_outlined,
                ].map((icon) => Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _green.withValues(alpha: 0.1),
                    border: Border.all(color: _green.withValues(alpha: 0.3)),
                  ),
                  child: Icon(icon, color: _green, size: 13),
                )).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: _bgDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Saber-ne més', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _buildCentralCard() {
    return Container(
      height: 340,
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _green.withValues(alpha: 0.2)),
      ),
      child: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [Color(0xFF1A3040), _cardDark],
                  ),
                ),
              ),
            ),
          ),
          // Eye tracking crosshair animation
          Center(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) {
                final opacity = 0.4 + 0.6 * _pulse.value;
                return Opacity(
                  opacity: opacity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer circle
                      Container(
                        width: 160, height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _green.withValues(alpha: 0.3), width: 1.5),
                        ),
                      ),
                      // Inner circle
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _green.withValues(alpha: 0.6), width: 1.5),
                        ),
                      ),
                      // Center: person avatar
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: _green.withValues(alpha: 0.15),
                        child: const Icon(Icons.person, color: _green, size: 34),
                      ),
                      // Crosshair lines
                      _crosshairLine(horizontal: true),
                      _crosshairLine(horizontal: false),
                    ],
                  ),
                );
              },
            ),
          ),
          // Top-left label
          Positioned(
            top: 20, left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _featureBadge(Icons.visibility_outlined, 'Eye Tracking'),
                const SizedBox(height: 8),
                _featureBadge(Icons.psychology_outlined, 'AI Interview'),
              ],
            ),
          ),
          // Bottom label
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _featureBadge(Icons.mic_none_rounded, 'Anàlisi de veu'),
                _featureBadge(Icons.picture_as_pdf_outlined, 'Informe PDF'),
              ],
            ),
          ),
          // Top right badge
          Positioned(
            top: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _green.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, color: _green, size: 7),
                  SizedBox(width: 6),
                  Text('En viu', style: TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _crosshairLine({required bool horizontal}) {
    return Container(
      width: horizontal ? 130 : 1.5,
      height: horizontal ? 1.5 : 130,
      color: _green.withValues(alpha: 0.5),
    );
  }

  Widget _featureBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _green, size: 13),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: _textLight, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.visibility_outlined,
          title: 'Eye Tracking',
          subtitle: 'Analitzem el contacte visual durant l\'entrevista en temps real.',
          hasChart: false,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.graphic_eq_rounded,
          title: 'Anàlisi de veu',
          subtitle: 'Velocitat, to i claredat del discurs analitzats per IA.',
          hasChart: true,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.picture_as_pdf_outlined,
          title: 'Informe PDF',
          subtitle: 'Rep un informe detallat amb punts de millora al final de cada sessió.',
          hasChart: false,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool hasChart,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _green, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: _textLight, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: const TextStyle(color: _textMuted, fontSize: 11, height: 1.4),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (hasChart) ...[
            const SizedBox(width: 8),
            _buildMiniBarChart(),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniBarChart() {
    final heights = [0.4, 0.7, 0.5, 0.9, 0.6, 0.8, 1.0];
    return SizedBox(
      width: 36, height: 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: heights.map((h) => Container(
          width: 3,
          height: 24 * h,
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(2),
          ),
        )).toList(),
      ),
    );
  }

  // ── BOTTOM FEATURES ───────────────────────────────────────────────────────
  Widget _buildFeaturesRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text('Funcionalitats',
              style: TextStyle(color: _textLight, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Tot el que necessites per dominar les entrevistes',
              style: TextStyle(color: _textMuted, fontSize: 13)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBottomFeatures() {
    final features = [
      _FeatureItem(Icons.smart_toy_outlined, 'Entrevistes amb IA',
          'L\'IA fa de entrevistador i adapta les preguntes al teu nivell.'),
      _FeatureItem(Icons.visibility_outlined, 'Eye Tracking',
          'Analitza el teu contacte visual i concentració durant la sessió.'),
      _FeatureItem(Icons.graphic_eq_rounded, 'Anàlisi de veu',
          'Detecta fillers, to i ritme del teu discurs en temps real.'),
      _FeatureItem(Icons.picture_as_pdf_outlined, 'Informe PDF',
          'Informe complet descarregable amb puntuacions i recomanacions.'),
      _FeatureItem(Icons.bar_chart_rounded, 'Dashboard',
          'Segueix la teva evolució i compara sessions anteriors.'),
      _FeatureItem(Icons.category_outlined, 'Múltiples categories',
          'Software, màrqueting, finances i moltes més categories.'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cols = constraints.maxWidth > 600 ? 3 : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: features.length,
            itemBuilder: (_, i) => _buildFeatureCard(features[i]),
          );
        },
      ),
    );
  }

  Widget _buildFeatureCard(_FeatureItem f) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(f.icon, color: _green, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(f.title,
                  style: const TextStyle(color: _textLight, fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 4),
              Text(f.subtitle,
                  style: const TextStyle(color: _textMuted, fontSize: 10, height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String subtitle;
  const _FeatureItem(this.icon, this.title, this.subtitle);
}
