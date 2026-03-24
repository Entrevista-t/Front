import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/interview_models.dart';
import '../services/api_service.dart';

const _green = Color(0xFF00D4A1);
const _bgDark = Color(0xFF0F1117);
const _cardDark = Color(0xFF1A1E2E);
const _textLight = Color(0xFFE8EAF0);
const _textMuted = Color(0xFF7B8099);

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
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _cardDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textLight),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Perfil',
            style: TextStyle(color: _textLight, fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/profile/edit'),
            icon: const Icon(Icons.edit_outlined, color: _green, size: 18),
            label: const Text('Editar', style: TextStyle(color: _green, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildUserCard(),
                const SizedBox(height: 20),
                _buildStatsRow(),
                const SizedBox(height: 28),
                const Text('Informes passats',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textLight)),
                const SizedBox(height: 14),
                if (_sessions.isEmpty) _buildEmptyState() else ..._sessions.map(_buildSessionTile),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2640), Color(0xFF1A1E2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _green.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: _green.withValues(alpha: 0.2),
            child: const Icon(Icons.person, color: _green, size: 42),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20, color: _textLight)),
                const SizedBox(height: 4),
                Text(_email, style: const TextStyle(color: _textMuted, fontSize: 13)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _green.withValues(alpha: 0.3)),
                  ),
                  child: const Text('Pla gratuït',
                      style: TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
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
        const SizedBox(width: 12),
        Expanded(child: _statCard('${_avgScore.toInt()}%', 'Puntuació\nmitja', Icons.bar_chart_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _statCard(_bestCategory, 'Millor\ncategoria', Icons.star_outline_rounded)),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(icon, color: _green, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15, color: _textLight),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: _textMuted, fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, color: _textMuted.withValues(alpha: 0.4), size: 52),
          const SizedBox(height: 14),
          const Text('Encara no has fet cap entrevista',
              style: TextStyle(color: _textMuted, fontSize: 14)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/interview/software'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: _bgDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Fer la primera entrevista',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile(InterviewSession session) {
    final scoreColor = session.overallScore >= 75
        ? _green
        : session.overallScore >= 50
            ? Colors.orange
            : Colors.redAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: scoreColor.withValues(alpha: 0.15),
          child: Text('${session.overallScore.toInt()}',
              style: TextStyle(
                  color: scoreColor, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        title: Text(session.categoryName,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14, color: _textLight)),
        subtitle: Text(session.formattedDate,
            style: const TextStyle(color: _textMuted, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: _textMuted),
        onTap: () => context.go('/results/${session.id}'),
      ),
    );
  }
}
