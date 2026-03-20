import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/interview_models.dart';
import '../services/api_service.dart';

const _pink = Color(0xFFE91E8C);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<InterviewCategory> _categories = [];
  List<InterviewSession> _recentSessions = [];
  bool _loading = true;
  int _selectedDrawerIndex = 0;

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
      backgroundColor: Colors.grey[50],
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.grey[200],
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text("Entrevista't", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: _pink.withValues(alpha: 0.15),
              child: const Icon(Icons.person, color: _pink, size: 20),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _pink))
          : RefreshIndicator(
              color: _pink,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildPerformanceCard(),
                  const SizedBox(height: 24),
                  const Text('Categories',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 14),
                  _buildCategoriesGrid(),
                  if (_recentSessions.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sessions recents',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        Text('Veure totes',
                            style: TextStyle(color: _pink, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._recentSessions.map(_buildSessionTile),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // User header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 16, 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _pink.withValues(alpha: 0.15),
                    child: const Icon(Icons.person, color: _pink, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Usuari', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('usuari@entrevistat.com',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey[200], height: 1),
            const SizedBox(height: 8),

            // Menu items
            _drawerItem(Icons.home_rounded, 'Home', 0, context),
            _drawerItem(Icons.bar_chart_rounded, 'Informes', 1, context),
            _drawerItem(Icons.person_outline_rounded, 'Perfil', 2, context),

            const Spacer(),
            Divider(color: Colors.grey[200], height: 1),
            _drawerItem(Icons.settings_rounded, 'Configuració', 3, context),
            const SizedBox(height: 12),

            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.grey),
                title: Text('Tancar sessió', style: TextStyle(color: Colors.grey[700])),
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

  Widget _drawerItem(IconData icon, String label, int index, BuildContext context) {
    final selected = _selectedDrawerIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: selected ? _pink : Colors.grey[500]),
        title: Text(label,
            style: TextStyle(
              color: selected ? _pink : Colors.grey[700],
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            )),
        trailing: Icon(Icons.chevron_right, color: selected ? _pink : Colors.grey[400], size: 20),
        tileColor: selected ? _pink.withValues(alpha: 0.08) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {
          setState(() { _selectedDrawerIndex = index; });
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildPerformanceCard() {
    final avg = _averageScore;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rendiment General',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              Text('Últim mes', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Circular progress
              SizedBox(
                width: 90, height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: avg / 100,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation(_pink),
                      strokeCap: StrokeCap.round,
                    ),
                    Text('${avg.toInt()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_recentSessions.length} sessions',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text('completades', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    const SizedBox(height: 12),
                    _buildMiniStat(Icons.trending_up_rounded, 'Millora progressiva', Colors.green),
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
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/interview/${cat.id}'),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _pink.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(cat.icon, color: _pink, size: 22),
              ),
              Text(cat.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionTile(InterviewSession session) {
    final scoreColor = session.overallScore >= 75
        ? Colors.green
        : session.overallScore >= 50
            ? Colors.orange
            : Colors.red;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.06), blurRadius: 6)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: scoreColor.withValues(alpha: 0.12),
          child: Text(
            '${session.overallScore.toInt()}',
            style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        title: Text(session.categoryName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(session.formattedDate, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => context.go('/results/${session.id}'),
      ),
    );
  }
}
