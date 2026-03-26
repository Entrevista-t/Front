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

class _ProfileScreenState extends State<ProfileScreen> {
  List<InterviewSession> _sessions = [];
  bool _loading = true;
  String _name = 'Usuari';
  String _email = 'usuari@entrevistat.com';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('user_name') ?? 'Usuari';
      _email = prefs.getString('user_email') ?? 'usuari@entrevistat.com';
    });
    try {
      final sessions = await ApiService.getRecentSessions();
      setState(() { _sessions = sessions; });
    } catch (_) {
      // sense sessions
    } finally {
      setState(() { _loading = false; });
    }
  }

  double get _avgScore {
    if (_sessions.isEmpty) return 0;
    return _sessions.map((s) => s.overallScore).reduce((a, b) => a + b) / _sessions.length;
  }

  String get _bestCategory {
    if (_sessions.isEmpty) return '-';
    return _sessions.reduce((a, b) => a.overallScore > b.overallScore ? a : b).categoryName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgBase,
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
                  ..._sessions.map((s) => SessionTile(
                    session: s,
                    onTap: () => context.go('/results/${s.id}'),
                  )),
                const SizedBox(height: kS24),
              ],
            ),
    );
  }

  Widget _buildUserCard() {
    return AppCard(
      color: kBgElevated,
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: kAccent.withValues(alpha: 0.15),
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
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _statCard('${_sessions.length}', 'Sessions', Icons.videocam_outlined)),
        const SizedBox(width: kS12),
        Expanded(child: _statCard('${_avgScore.toInt()}%', 'Puntuació\nmitja', Icons.bar_chart_rounded)),
        const SizedBox(width: kS12),
        Expanded(child: _statCard(_bestCategory, 'Millor\ncategoria', Icons.star_outline_rounded)),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: kS16, horizontal: kS12),
      child: Column(
        children: [
          Icon(icon, color: kAccent, size: 20),
          const SizedBox(height: kS8),
          Text(value,
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
