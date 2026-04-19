import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class ReportSentScreen extends StatefulWidget {
  final String sessionId;
  const ReportSentScreen({super.key, required this.sessionId});

  @override
  State<ReportSentScreen> createState() => _ReportSentScreenState();
}

class _ReportSentScreenState extends State<ReportSentScreen>
    with TickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  late final AnimationController _particleCtrl;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _scale = CurvedAnimation(parent: _anim, curve: Curves.elasticOut);
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: kS32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 140, height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _particleCtrl,
                        builder: (context, _) => CustomPaint(
                          size: const Size(140, 140),
                          painter: _ParticlePainter(
                            progress: _particleCtrl.value,
                            color: kScoreGood,
                          ),
                        ),
                      ),
                      ScaleTransition(
                        scale: _scale,
                        child: Container(
                          width: 110, height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kScoreGood.withValues(alpha: 0.1),
                            border: Border.all(color: kScoreGood.withValues(alpha: 0.4), width: 2),
                          ),
                          child: const Icon(Icons.check_circle_outline_rounded, color: kScoreGood, size: 52),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: kS32),
                Text(
                  'Entrevista enviada!',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kS16),
                Text(
                  "El teu video s'esta analitzant.\nEls resultats estaran disponibles en pocs minuts.",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.6),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kS48),
                ElevatedButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_rounded, size: 20),
                  label: const Text("Tornar a l'inici"),
                ),
                const SizedBox(height: kS24),
                TextButton(
                  onPressed: () => context.go('/results/${widget.sessionId}'),
                  child: const Text('Veure resultats complets'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  static final List<_Particle> _particles = _generateParticles(20);

  _ParticlePainter({required this.progress, required this.color});

  static List<_Particle> _generateParticles(int count) {
    final rng = Random(42);
    return List.generate(count, (_) {
      final angle = rng.nextDouble() * 2 * pi;
      final speed = 0.6 + rng.nextDouble() * 0.6;
      final size = 2.0 + rng.nextDouble() * 3.0;
      return _Particle(angle: angle, speed: speed, size: size);
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    for (final p in _particles) {
      final dist = maxRadius * progress * p.speed;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      if (opacity <= 0) continue;
      final paint = Paint()..color = color.withValues(alpha: opacity * 0.7);
      final offset = Offset(
        center.dx + cos(p.angle) * dist,
        center.dy + sin(p.angle) * dist,
      );
      canvas.drawCircle(offset, p.size * (1.0 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  const _Particle({required this.angle, required this.speed, required this.size});
}
