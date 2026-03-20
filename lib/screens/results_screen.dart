import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/interview_models.dart';
import '../services/api_service.dart';

const _pink = Color(0xFFE91E8C);

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
          const SnackBar(content: Text('PDF descarregat correctament'), backgroundColor: _pink),
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
            CircularProgressIndicator(color: _pink),
            SizedBox(height: 16),
            Text('Obtenint resultats de la IA...'),
          ],
        )),
      );
    }

    final r = _result!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.grey[200],
        leading: IconButton(
          icon: const Icon(Icons.home_rounded, color: Colors.black87),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Informes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _pink.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Menú', style: TextStyle(color: _pink, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          IconButton(
            icon: _downloading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: _pink, strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_rounded, color: Colors.black54),
            onPressed: _downloading ? null : _downloadPdf,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildCategoryHeader(r),
          const SizedBox(height: 20),
          _buildPerformanceSection(r),
          const SizedBox(height: 20),
          _buildStrengthsWeaknessesChart(r),
          const SizedBox(height: 20),
          _buildAiFeedback(r),
          const SizedBox(height: 20),
          _buildDetailCards(r),
          const SizedBox(height: 24),
          _buildReportsList(r),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              minimumSize: const Size(double.infinity, 52),
              elevation: 4,
              shadowColor: _pink.withValues(alpha: 0.4),
            ),
            child: const Text('Nova simulació', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(InterviewResult r) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _pink.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(r.categoryName, style: const TextStyle(color: _pink, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        const SizedBox(width: 10),
        Text(r.formattedDate, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      ],
    );
  }

  Widget _buildPerformanceSection(InterviewResult r) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Performance',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _circleScore('Contingut', r.contentScore, const Color(0xFF4CAF50)),
              _circleScore('Fluïdesa', r.fluencyScore, _pink),
              _circleScore('Seguretat', r.confidenceScore, const Color(0xFF5C6BC0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleScore(String label, double value, Color color) {
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
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(color),
                strokeCap: StrokeCap.round,
              ),
              Text(
                '${value.toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildStrengthsWeaknessesChart(InterviewResult r) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Strengths & Weaknesses',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 20),
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
                        const labels = ['Cont.', 'Flu.', 'Mir.', 'Str.', 'Con.'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(labels[value.toInt()],
                              style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: [
                  _bar(0, r.contentScore, Colors.grey[350]!),
                  _bar(1, r.fluencyScore, _pink),
                  _bar(2, r.eyeContactPercent, Colors.grey[350]!),
                  _bar(3, r.structureScore, _pink),
                  _bar(4, r.confidenceScore, Colors.grey[350]!),
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      ),
    ]);
  }

  Widget _buildAiFeedback(InterviewResult r) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome_rounded, color: _pink, size: 18),
            const SizedBox(width: 8),
            const Text('Feedback IA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          ]),
          const SizedBox(height: 12),
          Text(r.aiFeedback, style: TextStyle(color: Colors.grey[600], height: 1.55, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDetailCards(InterviewResult r) {
    return Row(
      children: [
        Expanded(
          child: _miniCard(r.wordsPerMinute.toStringAsFixed(0), 'ppm', Icons.speed_rounded, const Color(0xFF5C6BC0)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniCard('${r.eyeContactPercent.toStringAsFixed(0)}%', 'contacte visual', Icons.visibility_rounded, const Color(0xFF4CAF50)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniCard('${r.excessivePauses}', 'pauses llargues', Icons.pause_rounded, Colors.orange),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniCard('${r.fillerWordsCount}', 'paraules falca', Icons.record_voice_over_rounded, _pink),
        ),
      ],
    );
  }

  Widget _miniCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.08), blurRadius: 6)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[500]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildReportsList(InterviewResult r) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reports',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 12),
          Divider(color: Colors.grey[200], height: 1),
          // Strengths
          ...r.strengths.asMap().entries.map((e) => _reportItem(
                'Punt Fort ${e.key + 1}',
                e.value,
                const Color(0xFF4CAF50),
              )),
          // Improvements
          ...r.improvements.asMap().entries.map((e) => _reportItem(
                'A Millorar ${e.key + 1}',
                e.value,
                _pink,
              )),
        ],
      ),
    );
  }

  Widget _reportItem(String title, String subtitle, Color avatarColor) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: avatarColor.withValues(alpha: 0.15),
              child: Icon(Icons.person, color: avatarColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Divider(color: Colors.grey[200], height: 1),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}
