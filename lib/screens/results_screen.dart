import 'package:fl_chart/fl_chart.dart';
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

class _ResultsScreenState extends State<ResultsScreen> {
  InterviewResult? _result;
  bool _loading = true;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await ApiService.getResults(widget.sessionId);
      setState(() { _result = r; });
    } catch (_) {
      setState(() { _result = InterviewResult.mock(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _downloadPdf() async {
    setState(() { _downloading = true; });
    try {
      await ApiService.downloadPdf(widget.sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF descarregat correctament')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      setState(() { _downloading = false; });
    }
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

    final r = _result!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Informe'),
        actions: [
          IconButton(
            icon: _downloading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_rounded),
            onPressed: _downloading ? null : _downloadPdf,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(kPagePadding),
        children: [
          _buildCategoryHeader(r),
          const SizedBox(height: kS16),
          _buildPerformanceSection(r),
          const SizedBox(height: kS16),
          _buildStrengthsWeaknessesChart(r),
          const SizedBox(height: kS16),
          _buildAiFeedback(r),
          const SizedBox(height: kS16),
          _buildDetailCards(r),
          const SizedBox(height: kS16),
          _buildReportsList(r),
          const SizedBox(height: kS24),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Nova simulació'),
          ),
          const SizedBox(height: kS8),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(InterviewResult r) {
    return Row(
      children: [
        AppChip(r.categoryName),
        const SizedBox(width: kS8),
        Text(r.formattedDate, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildPerformanceSection(InterviewResult r) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: 'Rendiment'),
          const SizedBox(height: kS24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
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

  Widget _circleScore(String label, double value) {
    final color = scoreColor(value);
    return Column(
      children: [
        SizedBox(
          width: 82, height: 82,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value / 100,
                strokeWidth: 9,
                backgroundColor: kBorderSubtle,
                valueColor: AlwaysStoppedAnimation(color),
                strokeCap: StrokeCap.round,
              ),
              Text(
                '${value.toInt()}%',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: kS8),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  Widget _buildStrengthsWeaknessesChart(InterviewResult r) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: 'Punts forts i febles'),
          const SizedBox(height: kS24),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        const labels = ['Cont.', 'Fluï.', 'Mirad.', 'Estr.', 'Conf.'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[value.toInt()],
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: [
                  _bar(0, r.contentScore, kAccent.withValues(alpha: 0.5)),
                  _bar(1, r.fluencyScore, kAccent),
                  _bar(2, r.eyeContactPercent, kAccent.withValues(alpha: 0.5)),
                  _bar(3, r.structureScore, kAccent),
                  _bar(4, r.confidenceScore, kAccent.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _bar(int x, double value, Color color) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(
        toY: value,
        color: color,
        width: 22,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(kRadiusSm)),
      ),
    ]);
  }

  Widget _buildAiFeedback(InterviewResult r) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome_rounded, color: kAccent, size: 18),
            const SizedBox(width: kS8),
            AppSectionHeader(title: 'Feedback IA'),
          ]),
          const SizedBox(height: kS12),
          Text(
            r.aiFeedback,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: kTextSecondary, height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCards(InterviewResult r) {
    return Row(
      children: [
        Expanded(
          child: _miniCard(r.wordsPerMinute.toStringAsFixed(0), 'ppm', Icons.speed_rounded),
        ),
        const SizedBox(width: kS8),
        Expanded(
          child: _miniCard('${r.eyeContactPercent.toStringAsFixed(0)}%', 'contacte visual', Icons.visibility_rounded),
        ),
        const SizedBox(width: kS8),
        Expanded(
          child: _miniCard('${r.excessivePauses}', 'pauses llargues', Icons.pause_rounded),
        ),
        const SizedBox(width: kS8),
        Expanded(
          child: _miniCard('${r.fillerWordsCount}', 'paraules falca', Icons.record_voice_over_rounded),
        ),
      ],
    );
  }

  Widget _miniCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: kS16, horizontal: kS8),
      decoration: BoxDecoration(
        color: kBgSurface,
        borderRadius: BorderRadius.circular(kRadiusMd),
        border: Border.all(color: kBorderSubtle),
      ),
      child: Column(
        children: [
          Icon(icon, color: kAccent, size: 18),
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
          AppSectionHeader(title: 'Resum'),
          const SizedBox(height: kS12),
          const Divider(),
          ...r.strengths.asMap().entries.map((e) => _reportItem(
                'Punt fort ${e.key + 1}',
                e.value,
                kScoreGood,
                Icons.check_circle_outline_rounded,
              )),
          ...r.improvements.asMap().entries.map((e) => _reportItem(
                'A millorar ${e.key + 1}',
                e.value,
                kScoreMid,
                Icons.arrow_upward_rounded,
              )),
        ],
      ),
    );
  }

  Widget _reportItem(String title, String subtitle, Color color, IconData icon) {
    return Column(
      children: [
        const SizedBox(height: kS12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(kS8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(kRadiusSm),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: kS12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: kS4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: kS12),
        const Divider(),
      ],
    );
  }
}
