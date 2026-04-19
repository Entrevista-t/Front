import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/interview_models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_card.dart';
import '../widgets/app_section_header.dart';

class ResultsScreen extends StatefulWidget {
  final String sessionId;

  const ResultsScreen({super.key, required this.sessionId});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

/// Total number of staggered sections for entrance animation.
const _sectionCount = 6;

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  InterviewResult? _result;
  bool _loading = true;
  String? _error;
  // Animated score circles controller
  late final AnimationController _scoreCtrl;

  // Staggered entrance controller
  late final AnimationController _staggerCtrl;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  @override
  void initState() {
    super.initState();

    _scoreCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600 + (_sectionCount - 1) * 100),
    );

    // Pre-build staggered intervals
    final totalMs = 600 + (_sectionCount - 1) * 100;
    _fadeAnims = List.generate(_sectionCount, (i) {
      final start = (i * 100) / totalMs;
      final end = (i * 100 + 600) / totalMs;
      return CurvedAnimation(
        parent: _staggerCtrl,
        curve: Interval(start, end.clamp(0.0, 1.0), curve: kCurveEntrance),
      );
    });
    _slideAnims = List.generate(_sectionCount, (i) {
      final start = (i * 100) / totalMs;
      final end = (i * 100 + 600) / totalMs;
      return Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _staggerCtrl,
        curve: Interval(start, end.clamp(0.0, 1.0), curve: kCurveEntrance),
      ));
    });

    _load();
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await ApiService.getResults(widget.sessionId);
      setState(() { _result = r; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      setState(() { _loading = false; });
      if (_result != null) {
        _scoreCtrl.forward();
        _staggerCtrl.forward();
      }
    }
  }

  /// Wraps a section widget with staggered fade + slide entrance.
  Widget _entrance(int index, Widget child) {
    return SlideTransition(
      position: _slideAnims[index],
      child: FadeTransition(
        opacity: _fadeAnims[index],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: kS16),
            Text('Obtenint resultats de la IA...'),
          ],
        )),
      );
    }

    if (_error != null || _result == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.home_rounded),
            onPressed: () => context.go('/home'),
          ),
          title: const Text('Informe'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(kS32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 64, color: context.colors.textTertiary),
                const SizedBox(height: kS24),
                Text(
                  'No s\'han pogut carregar els resultats',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kS12),
                Text(
                  _error ?? 'Error desconegut',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary, height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kS32),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() { _loading = true; _error = null; });
                    _load();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Tornar a intentar'),
                ),
                const SizedBox(height: kS12),
                TextButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_rounded, size: 20),
                  label: const Text("Tornar a l'inici"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final r = _result!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Informe'),
        actions: const [],
      ),
      body: ListView(
        padding: const EdgeInsets.all(kPagePadding),
        children: [
          _entrance(0, _buildCategoryHeader(r)),
          const SizedBox(height: kS24),
          _entrance(1, _buildPerformanceRow(r)),
          const SizedBox(height: kS16),
          _entrance(2, _buildTranscript(r)),
          const SizedBox(height: kS16),
          _entrance(3, _buildDetailCards(r)),
          const SizedBox(height: kS16),
          _entrance(4, _buildReportsList(r)),
          const SizedBox(height: kS24),
          _entrance(5, ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Nova simulació'),
          )),
          const SizedBox(height: kS8),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(InterviewResult r) {
    final color = scoreColor(r.overallScore);
    final curved = CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutCubic);
    final tween = Tween<double>(begin: 0, end: r.overallScore / 100);

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final animValue = tween.evaluate(curved);
        return Center(
          child: Column(
            children: [
              SizedBox(
                width: 160, height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 160, height: 160,
                      child: CircularProgressIndicator(
                        value: animValue,
                        strokeWidth: 12,
                        backgroundColor: context.colors.borderSubtle,
                        valueColor: AlwaysStoppedAnimation(color),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(animValue * 100).toInt()}%',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold, color: color,
                          ),
                        ),
                        Text(
                          'Puntuació global',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerformanceRow(InterviewResult r) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 600;
        final rendiment = _buildRendimentCard(r);
        final punts = _buildStrengthsBars(r);
        if (wide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: rendiment),
                const SizedBox(width: kS16),
                Expanded(child: punts),
              ],
            ),
          );
        }
        return Column(children: [
          rendiment,
          const SizedBox(height: kS16),
          punts,
        ]);
      },
    );
  }

  Widget _buildRendimentCard(InterviewResult r) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: 'Rendiment'),
          const SizedBox(height: kS24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _circleScore('Contingut', r.contentScore),
              _circleScore('Fluïdesa', r.fluencyScore),
              _circleScore('Seguretat', r.confidenceScore),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthsBars(InterviewResult r) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: 'Punts forts i febles'),
          const SizedBox(height: kS20),
          _horizontalBar('Contingut', r.contentScore),
          const SizedBox(height: kS16),
          _horizontalBar('Fluïdesa', r.fluencyScore),
          const SizedBox(height: kS16),
          _horizontalBar('Lèxic', r.lexicalScore),
          const SizedBox(height: kS16),
          _horizontalBar('Estructura', r.structureScore),
          const SizedBox(height: kS16),
          _horizontalBar('Seguretat', r.confidenceScore),
        ],
      ),
    );
  }

  Widget _horizontalBar(String label, double value) {
    final color = scoreColor(value);
    final curved = CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutCubic);
    final tween = Tween<double>(begin: 0, end: (value / 100).clamp(0.0, 1.0));

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final animValue = tween.evaluate(curved);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  '${(animValue * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600, color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: kS4),
            ClipRRect(
              borderRadius: BorderRadius.circular(kRadiusSm),
              child: LinearProgressIndicator(
                value: animValue,
                minHeight: 10,
                backgroundColor: context.colors.borderSubtle,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _circleScore(String label, double value) {
    final color = scoreColor(value);
    final curved = CurvedAnimation(
      parent: _scoreCtrl,
      curve: Curves.easeOutCubic,
    );
    final tween = Tween<double>(begin: 0, end: value / 100);

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final animValue = tween.evaluate(curved);
        return Column(
          children: [
            SizedBox(
              width: 130, height: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 130, height: 130,
                    child: CircularProgressIndicator(
                      value: animValue,
                      strokeWidth: 10,
                      backgroundColor: context.colors.borderSubtle,
                      valueColor: AlwaysStoppedAnimation(color),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '${(animValue * 100).toInt()}%',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: kS8),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        );
      },
    );
  }

  Widget _buildTranscript(InterviewResult r) {
    final radius = BorderRadius.circular(kRadiusMd);
    return Container(
      decoration: BoxDecoration(
        gradient: context.colors.gradientCardBorder,
        borderRadius: radius,
      ),
      child: Container(
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.all(kS24),
        decoration: BoxDecoration(
          color: context.colors.bgSurface,
          borderRadius: radius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.text_snippet_rounded, color: kAccent, size: 18),
              const SizedBox(width: kS8),
              AppSectionHeader(title: 'Transcripció'),
            ]),
            const SizedBox(height: kS12),
            Text(
              r.transcript ?? 'No disponible',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary, height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCards(InterviewResult r) {
    return Row(
      children: [
        Expanded(child: _miniCard(r.wordsPerMinute.toStringAsFixed(0), 'Paraules per minut', Icons.speed_rounded)),
        const SizedBox(width: kS8),
        Expanded(child: _miniCard('${r.speechRatio.toStringAsFixed(0)}%', 'Temps de parla', Icons.mic_rounded)),
        const SizedBox(width: kS8),
        Expanded(child: _miniCard(_emotionLabel(r.dominantEmotion), 'Emoció predominant', Icons.face_rounded)),
        const SizedBox(width: kS8),
        Expanded(child: _miniCard('${r.lexicalScore.toStringAsFixed(0)}%', 'Riquesa lèxica', Icons.auto_stories_rounded)),
      ],
    );
  }

  Widget _miniCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: kS16, horizontal: kS8),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: BorderRadius.circular(kRadiusMd),
        border: Border.all(color: context.colors.borderSubtle),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(kS6),
            decoration: BoxDecoration(
              color: kAccent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(kRadiusSm),
              boxShadow: [
                BoxShadow(
                  color: kAccent.withValues(alpha: 0.08),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: kAccent, size: 18),
          ),
          const SizedBox(height: kS8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: kS4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList(InterviewResult r) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: 'Detall de metriques'),
          const SizedBox(height: kS12),
          const Divider(),
          _reportItem('Alineació amb la pregunta', (r.questionAlignment ?? 0).toStringAsFixed(2), kAccent, Icons.track_changes_rounded,
            description: "Mesura com de relacionada està la resposta amb la pregunta formulada."),
          _reportItem('Coherència del discurs', (r.discourseCoherence ?? 0).toStringAsFixed(2), kAccent, Icons.linear_scale_rounded,
            description: "Avalua la connexió lògica i el fil conductor entre les idees exposades."),
          _reportItem('Densitat informativa', (r.informationDensity ?? 0).toStringAsFixed(2), kAccent, Icons.density_medium_rounded,
            description: "Proporció de paraules amb contingut rellevant respecte al total."),
          _reportItem("Índex d'especificitat", (r.specificityIndex ?? 0).toStringAsFixed(2), kAccent, Icons.precision_manufacturing_rounded,
            description: "Grau de concreció i detall en la resposta, evitant generalitats."),
          _reportItem('Estabilitat emocional', (r.emotionalConsistency ?? 0).toStringAsFixed(2), kAccent, Icons.psychology_rounded,
            description: "Consistència de les expressions facials durant la resposta."),
        ],
      ),
    );
  }

  Widget _reportItem(String label, String value, Color color, IconData icon, {String? description}) {
    return Column(
      children: [
        const SizedBox(height: kS12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(kS8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(kRadiusSm),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: kS12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleSmall),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.textTertiary, height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: kS8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: kS12),
        const Divider(),
      ],
    );
  }

  static const _emotionTranslations = {
    'positive': 'Positiva',
    'neutral': 'Neutral',
    'tense': 'Tensa',
  };

  String _emotionLabel(String? emotion) {
    if (emotion == null) return '-';
    return _emotionTranslations[emotion.toLowerCase()] ?? emotion;
  }
}
