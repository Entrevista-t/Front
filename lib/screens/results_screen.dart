import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/interview_models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_card.dart';
import '../widgets/app_section_header.dart';
import '../widgets/dot_grid_background.dart';

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
      var r = await ApiService.getResults(widget.sessionId);
      // Fetch question text from interview detail
      try {
        final interview = await ApiService.getInterviewById(widget.sessionId);
        if (interview.questionId != null) {
          final qText = await ApiService.getQuestionText(interview.questionId!);
          if (qText != null) {
            r = InterviewResult(
              interviewId: r.interviewId,
              status: r.status,
              transcript: r.transcript,
              questionText: qText,
              durationTotal: r.durationTotal,
              activeSpeechTime: r.activeSpeechTime,
              confidenceIndex: r.confidenceIndex,
              communicationRhythmWpm: r.communicationRhythmWpm,
              questionAlignment: r.questionAlignment,
              discourseCoherence: r.discourseCoherence,
              informationDensity: r.informationDensity,
              specificityIndex: r.specificityIndex,
              lexicalRichness: r.lexicalRichness,
              emotionDistribution: r.emotionDistribution,
              dominantEmotion: r.dominantEmotion,
              emotionalConsistency: r.emotionalConsistency,
              llmFeedback: r.llmFeedback,
              answerQualityScore: r.answerQualityScore,
            );
          }
        }
      } catch (_) {
        // Silently ignore question fetch errors
      }
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
            onPressed: () => context.go('/profile'),
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
                  onPressed: () => context.go('/profile'),
                  icon: const Icon(Icons.person_rounded, size: 20),
                  label: const Text('Tornar al perfil'),
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
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
        title: const Text('Informe'),
        actions: const [],
      ),
      body: DotGridBackground(
        child: Center(
          child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(kPagePadding),
            children: [
              _entrance(0, _buildCategoryHeader(r)),
              const SizedBox(height: kS24),
              _entrance(1, _buildLlmFeedback(r)),
              const SizedBox(height: kS16),
              _entrance(2, _buildPerformanceRow(r)),
              const SizedBox(height: kS16),
              _entrance(3, _buildTranscript(r)),
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
        ),
      ),
      ),
    );
  }

  Widget _buildCategoryHeader(InterviewResult r) {
    final color = scoreColor(r.overallScore);
    final curved = CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutCubic);
    final tween = Tween<double>(begin: 0, end: r.overallScore / 100);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: kS24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kRadiusLg),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            kAccent.withValues(alpha: 0.03),
            Colors.transparent,
          ],
        ),
      ),
      child: AnimatedBuilder(
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
    ),
    );
  }

  Widget _buildPerformanceRow(InterviewResult r) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth.clamp(0.0, 900.0) - kPagePadding * 2;
    // 7 circles: size based on fitting ~4 per row on wide, ~3 on narrow
    final cols = contentWidth >= 600 ? 7 : (contentWidth >= 400 ? 4 : 3);
    final circleSize = ((contentWidth - kS24 * 2 - kS16 * (cols - 1)) / cols).clamp(55.0, 100.0);

    final metrics = [
      ('Contingut', r.contentScore),
      ('Fluïdesa', r.fluencyScore),
      ('Estructura', r.structureScore),
      ('Seguretat', r.confidenceScore),
      ('Lèxic', r.lexicalScore),
      ('Qualitat', r.answerQualityPercent),
      ('Emocional', r.emotionalConsistencyScore),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: 'Rendiment'),
          const SizedBox(height: kS24),
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: kS16,
            runSpacing: kS20,
            children: metrics.map((m) => _circleScore(m.$1, m.$2, circleSize)).toList(),
          ),
          const SizedBox(height: kS8),
        ],
      ),
    );
  }

  Widget _circleScore(String label, double value, double size) {
    final color = scoreColor(value);
    final curved = CurvedAnimation(
      parent: _scoreCtrl,
      curve: Curves.easeOutCubic,
    );
    final tween = Tween<double>(begin: 0, end: value / 100);
    final strokeWidth = (size * 0.077).clamp(4.0, 10.0);
    final fontSize = size < 80 ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.titleLarge;

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final animValue = tween.evaluate(curved);
        return Column(
          children: [
            SizedBox(
              width: size, height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: size, height: size,
                    child: CircularProgressIndicator(
                      value: animValue,
                      strokeWidth: strokeWidth,
                      backgroundColor: context.colors.borderSubtle,
                      valueColor: AlwaysStoppedAnimation(color),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '${(animValue * 100).toInt()}%',
                    style: fontSize,
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

  Widget _buildLlmFeedback(InterviewResult r) {
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
              const Icon(Icons.auto_awesome_rounded, color: kAccent, size: 18),
              const SizedBox(width: kS8),
              AppSectionHeader(title: 'Feedback'),
            ]),
            const SizedBox(height: kS12),
            Text(
              r.llmFeedback ?? 'Feedback no disponible',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary, height: 1.6,
              ),
            ),
          ],
        ),
      ),
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
            if (r.questionText != null) ...[
              const SizedBox(height: kS16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(kS12),
                decoration: BoxDecoration(
                  color: kAccent.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(kRadiusSm),
                  border: Border.all(color: kAccent.withValues(alpha: 0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.help_outline_rounded, color: kAccent, size: 16),
                    const SizedBox(width: kS8),
                    Expanded(
                      child: Text(
                        r.questionText!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: kAccent,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

  Widget _buildReportsList(InterviewResult r) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: 'Detall de mètriques'),
          const SizedBox(height: kS12),
          const Divider(),
          _reportItem('Contingut', '${r.contentScore.toStringAsFixed(0)}%', kAccent, Icons.topic_rounded,
            description: "Mitjana d'alineació amb la pregunta, densitat informativa i especificitat."),
          _reportItem('Fluïdesa', '${r.fluencyScore.toStringAsFixed(0)}%', kAccent, Icons.speed_rounded,
            description: "Combinació del ritme de parla (paraules/minut) i la proporció de temps parlant."),
          _reportItem('Estructura', '${r.structureScore.toStringAsFixed(0)}%', kAccent, Icons.linear_scale_rounded,
            description: "Coherència global del discurs: connexió lògica entre les idees exposades."),
          _reportItem('Seguretat', '${r.confidenceScore.toStringAsFixed(0)}%', kAccent, Icons.shield_rounded,
            description: "Índex de confiança basat en el to de veu i la fermesa en la comunicació."),
          _reportItem('Riquesa lèxica', '${r.lexicalScore.toStringAsFixed(0)}%', kAccent, Icons.auto_stories_rounded,
            description: "Varietat i riquesa del vocabulari emprat en la resposta."),
          _reportItem('Qualitat de la resposta', '${r.answerQualityPercent.toStringAsFixed(0)}%', kAccent, Icons.verified_rounded,
            description: "Valoració global de com de bé la resposta aborda la pregunta formulada."),
          _reportItem('Estabilitat emocional', '${r.emotionalConsistencyScore.toStringAsFixed(0)}%', kAccent, Icons.psychology_rounded,
            description: "Consistència de les expressions facials durant la resposta."),
          _reportItem('Alineació amb la pregunta', (r.questionAlignment ?? 0).toStringAsFixed(2), kAccent, Icons.track_changes_rounded,
            description: "Mesura com de relacionada està la resposta amb la pregunta formulada."),
          _reportItem('Coherència del discurs', (r.discourseCoherence ?? 0).toStringAsFixed(2), kAccent, Icons.account_tree_rounded,
            description: "Avalua la connexió lògica i el fil conductor entre les idees exposades."),
          _reportItem('Densitat informativa', (r.informationDensity ?? 0).toStringAsFixed(2), kAccent, Icons.density_medium_rounded,
            description: "Proporció de paraules amb contingut rellevant respecte al total."),
          _reportItem("Índex d'especificitat", (r.specificityIndex ?? 0).toStringAsFixed(2), kAccent, Icons.precision_manufacturing_rounded,
            description: "Grau de concreció i detall en la resposta, evitant generalitats."),
          _reportItem('Paraules per minut', r.wordsPerMinute.toStringAsFixed(0), kAccent, Icons.timer_rounded,
            description: "Ritme de comunicació. El rang ideal és entre 120 i 170 paraules per minut."),
          _reportItem('Temps de parla', '${r.speechRatio.toStringAsFixed(0)}%', kAccent, Icons.mic_rounded,
            description: "Percentatge del temps total que s'ha dedicat a parlar activament."),
          _reportItem('Emoció predominant', _emotionLabel(r.dominantEmotion), kAccent, Icons.face_rounded,
            description: "L'expressió facial detectada amb més freqüència durant la resposta."),
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
