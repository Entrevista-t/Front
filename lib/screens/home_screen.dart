import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/interview_models.dart';
import '../services/api_service.dart';

const _green = Color(0xFF00D4A1);
const _bgDark = Color(0xFF0F1117);
const _cardDark = Color(0xFF1A1E2E);
const _textLight = Color(0xFFE8EAF0);
const _textMuted = Color(0xFF7B8099);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<InterviewCategory> _categories = [];
  List<InterviewSession> _recentSessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; });
    try {
      final cats = await ApiService.getCategories();
      final sessions = await ApiService.getRecentSessions();
      setState(() { _categories = cats; _recentSessions = sessions; });
    } catch (_) {
      setState(() { _categories = InterviewCategory.defaults(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  double get _averageScore {
    if (_recentSessions.isEmpty) return 0;
    return _recentSessions.map((s) => s.overallScore).reduce((a, b) => a + b) / _recentSessions.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: _cardDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textLight),
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_entrevistat.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            const Text("Entrevista't",
                style: TextStyle(fontWeight: FontWeight.bold, color: _textLight, fontSize: 18)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: _green.withValues(alpha: 0.2),
              child: const Icon(Icons.person, color: _green, size: 20),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : RefreshIndicator(
              color: _green,
              backgroundColor: _cardDark,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHeroSection(),
                  const SizedBox(height: 24),
                  _buildPerformanceCard(),
                  const SizedBox(height: 24),
                  const Text('Categories',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textLight)),
                  const SizedBox(height: 14),
                  _buildCategoriesGrid(),
                  if (_recentSessions.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sessions recents',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textLight)),
                        Text('Veure totes',
                            style: TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._recentSessions.map(_buildSessionTile),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2640), Color(0xFF0F1117)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _green.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _green.withValues(alpha: 0.3)),
                ),
                child: const Text('New', style: TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Master your\ninterviews with ',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _textLight, height: 1.25)),
          const Text('AI', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _green)),
          const SizedBox(height: 10),
          Text('Practica amb entrevistes simulades,\nanalitza el teu rendiment i millora cada dia.',
              style: TextStyle(color: _textMuted, fontSize: 13, height: 1.5)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/interview/software'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: _bgDark,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Fer entrevista', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: _cardDark,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 16, 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _green.withValues(alpha: 0.2),
                    child: const Icon(Icons.person, color: _green, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Usuari',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textLight)),
                        Text('usuari@entrevistat.com',
                            style: TextStyle(color: _textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: _textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
            const SizedBox(height: 8),
            _drawerItem(Icons.home_rounded, 'Home', context,
                onTap: () { Navigator.pop(context); context.go('/home'); }),
            _drawerItem(Icons.person_outline_rounded, 'Perfil', context,
                onTap: () { Navigator.pop(context); context.go('/profile'); }),
            _drawerItem(Icons.bar_chart_rounded, 'Informes', context,
                onTap: () { Navigator.pop(context); context.go('/profile'); }),
            const Spacer(),
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
            _drawerItem(Icons.edit_outlined, 'Editar perfil', context,
                onTap: () { Navigator.pop(context); context.go('/profile/edit'); }),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: _textMuted),
                title: const Text('Tancar sessió', style: TextStyle(color: _textMuted)),
                onTap: () async {
                  await ApiService.logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, BuildContext context,
      {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: _textMuted),
        title: Text(label,
            style: const TextStyle(color: _textMuted)),
        trailing: const Icon(Icons.chevron_right, color: _textMuted, size: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: onTap ?? () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildPerformanceCard() {
    final avg = _averageScore;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rendiment General',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textLight)),
              Text('Últim mes', style: TextStyle(color: _textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 90, height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: avg / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation(_green),
                      strokeCap: StrokeCap.round,
                    ),
                    Text('${avg.toInt()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _textLight)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_recentSessions.length} sessions',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: _textLight)),
                    const SizedBox(height: 4),
                    const Text('completades', style: TextStyle(color: _textMuted, fontSize: 13)),
                    const SizedBox(height: 12),
                    _buildMiniStat(Icons.trending_up_rounded, 'Millora progressiva', _green),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: _textMuted, fontSize: 12)),
      ],
    );
  }

  Widget _buildCategoriesGrid() {
    final cats = _categories.isEmpty ? InterviewCategory.defaults() : _categories;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3,
      ),
      itemCount: cats.length,
      itemBuilder: (_, i) => _buildCategoryCard(cats[i]),
    );
  }

  Widget _buildCategoryCard(InterviewCategory cat) {
    return Material(
      color: _cardDark,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/interview/${cat.id}'),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(cat.icon, color: _green, size: 22),
              ),
              Text(cat.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _textLight),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
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
          child: Text(
            '${session.overallScore.toInt()}',
            style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        title: Text(session.categoryName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _textLight)),
        subtitle: Text(session.formattedDate, style: const TextStyle(color: _textMuted, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: _textMuted),
        onTap: () => context.go('/results/${session.id}'),
      ),
    );
  }
}
