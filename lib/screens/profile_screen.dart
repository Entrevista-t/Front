import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/interview_models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_card.dart';
import '../widgets/app_section_header.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/session_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  List<InterviewSession> _sessions = [];
  bool _loading = true;
  String _name = 'Usuari';
  String _email = 'usuari@entrevistat.com';

  late final AnimationController _statsCtrl;
  late final AnimationController _listCtrl;

  @override
  void initState() {
    super.initState();
    _statsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _listCtrl = AnimationController(vsync: this);
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await ApiService.getUserProfile();
      setState(() {
        _name = profile['nom'] as String? ?? 'Usuari';
        _email = profile['email'] as String? ?? '';
      });
    } catch (_) {
      // Fall back to cached values
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _name = prefs.getString('user_name') ?? 'Usuari';
        _email = prefs.getString('user_email') ?? '';
      });
    }
    try {
      final sessions = await ApiService.getRecentSessions();
      setState(() { _sessions = sessions; });
    } catch (_) {}
    setState(() { _loading = false; });
    _statsCtrl.forward();
    _listCtrl
      ..duration = Duration(milliseconds: 600 + 100 * _sessions.length)
      ..forward();
  }

  double get _avgScore {
    final completed = _sessions.where((s) => s.overallScore != null).toList();
    if (completed.isEmpty) return 0;
    return completed.map((s) => s.overallScore!).reduce((a, b) => a + b) / completed.length;
  }

  String get _bestCategory {
    final completed = _sessions.where((s) => s.isCompleted).toList();
    if (completed.isEmpty) return '-';
    return 'Completades: ${completed.length}';
  }

  @override
  void dispose() {
    _statsCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgBase,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Perfil'),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/profile/edit'),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Editar'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(kPagePadding),
              children: [
                _buildUserCard(),
                const SizedBox(height: kS16),
                _buildStatsRow(),
                const SizedBox(height: kS32),
                AppSectionHeader(title: 'Informes passats'),
                const SizedBox(height: kS16),
                if (_sessions.isEmpty)
                  AppEmptyState(
                    icon: Icons.inbox_outlined,
                    message: 'Encara no has fet cap entrevista',
                    buttonLabel: 'Fer la primera entrevista',
                    onButtonTap: () => context.go('/home'),
                  )
                else
                  ..._sessions.asMap().entries.map((entry) {
                    final i = entry.key;
                    final s = entry.value;
                    final count = _sessions.length;
                    final begin = count > 0 ? (i / (count + 1)) : 0.0;
                    final end = count > 0 ? ((i + 1) / (count + 1)).clamp(0.0, 1.0) : 1.0;
                    final interval = CurvedAnimation(
                      parent: _listCtrl,
                      curve: Interval(begin, end, curve: kCurveEntrance),
                    );
                    return FadeTransition(
                      opacity: interval,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(interval),
                        child: SessionTile(
                          session: s,
                          onTap: () => context.go('/results/${s.id}'),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: kS24),
              ],
            ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: context.colors.gradientCardBorder,
        borderRadius: BorderRadius.circular(kRadiusMd),
      ),
      child: Container(
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.all(kS24),
        decoration: BoxDecoration(
          color: context.colors.bgElevated,
          borderRadius: BorderRadius.circular(kRadiusMd),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: kAccent.withValues(alpha: 0.08),
              child: const Icon(Icons.person, color: kAccent, size: 38),
            ),
            const SizedBox(width: kS16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: kS4),
                  Text(_email, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: kS12),
                  const AppChip('Pla gratuït'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _statCard('${_sessions.length}', 'Sessions', Icons.videocam_outlined, isNumeric: true)),
        const SizedBox(width: kS12),
        Expanded(child: _statCard('${_avgScore.toInt()}%', 'Puntuació\nmitja', Icons.bar_chart_rounded, isNumeric: true)),
        const SizedBox(width: kS12),
        Expanded(child: _statCard(_bestCategory, 'Millor\nresultat', Icons.star_outline_rounded)),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon, {bool isNumeric = false}) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: kS16, horizontal: kS12),
      child: Column(
        children: [
          Icon(icon, color: kAccent, size: 20),
          const SizedBox(height: kS8),
          isNumeric
              ? AnimatedBuilder(
                  animation: _statsCtrl,
                  builder: (_, __) {
                    final numericPart = RegExp(r'\d+').firstMatch(value);
                    if (numericPart == null) {
                      return Text(value,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center);
                    }
                    final target = int.parse(numericPart.group(0)!);
                    final curvedProgress = kCurveEntrance.transform(_statsCtrl.value);
                    final current = (target * curvedProgress).round();
                    final display = value.replaceFirst(numericPart.group(0)!, '$current');
                    return Text(display,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center);
                  },
                )
              : Text(value,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center),
          const SizedBox(height: kS4),
          Text(label,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
