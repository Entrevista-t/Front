import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../main.dart';
import '../models/interview_models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_section_header.dart';
import '../widgets/glow_icon.dart';
import '../widgets/session_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  static const _catDescriptions = {
    'software': 'Algorismes, arquitectura i sistemes',
    'data': 'Anàlisi de dades i machine learning',
    'design': 'UX/UI, prototipatge i recerca',
    'management': 'Lideratge, àgil i planificació',
    'marketing': 'Estratègia digital i xarxes',
    'general': 'Competències transversals',
  };

  List<InterviewCategory> _categories = [];
  List<InterviewCategory> _filteredCategories = [];
  List<InterviewSession> _recentSessions = [];
  bool _loading = true;
  final _searchController = TextEditingController();
  late final AnimationController _entranceCtrl;

  String get _greeting {
    final hour = DateTime.now().hour;
    final name = ApiService.devUserName ?? 'Usuari';
    if (hour < 12) return 'Bon dia, $name';
    if (hour < 20) return 'Bona tarda, $name';
    return 'Bona nit, $name';
  }

  void _restartEntrance(int count) {
    if (count == 0) return;
    final totalMs = 150 * (count - 1) + 400;
    _entranceCtrl.duration =
        Duration(milliseconds: totalMs.clamp(400, 2000));
    _entranceCtrl.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(vsync: this);
    _load();
    _searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterCategories() {
    final q = _searchController.text.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filteredCategories = _allCats;
      } else {
        _filteredCategories = _allCats
            .where((c) =>
                c.name.toLowerCase().contains(q) ||
                (_catDescriptions[c.id] ?? '').toLowerCase().contains(q))
            .toList();
      }
    });
    _restartEntrance(_filteredCategories.length);
  }

  List<InterviewCategory> get _allCats =>
      _categories.isEmpty ? InterviewCategory.defaults() : _categories;

  Future<void> _load() async {
    setState(() { _loading = true; });
    try {
      final cats = await ApiService.getCategories();
      final sessions = await ApiService.getRecentSessions();
      setState(() { _categories = cats; _recentSessions = sessions; });
    } catch (_) {
      setState(() { _categories = InterviewCategory.defaults(); });
    } finally {
      setState(() {
        _filteredCategories = _allCats;
        _loading = false;
      });
      _restartEntrance(_filteredCategories.length);
    }
  }

  double get _averageScore {
    if (_recentSessions.isEmpty) return 0;
    return _recentSessions.map((s) => s.overallScore).reduce((a, b) => a + b) / _recentSessions.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgBase,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Center(
          child: GestureDetector(
            onTap: () => context.go('/landing'),
            child: Image.asset(
              'assets/images/logo_entrevistat.png',
              width: 34, height: 34,
              fit: BoxFit.contain,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: kS12),
            child: _ProfileMenuButton(
              onProfile: () => context.go('/profile'),
              onEdit: () => context.go('/profile/edit'),
              onLogout: () {
                ApiService.logout().then((_) {
                  if (context.mounted) context.go('/login');
                });
              },
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: kAccent,
              backgroundColor: kBgSurface,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: kS24),
                children: [
                  // ── Welcome text (centered) ─────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
                    child: Column(children: [
                      Text(
                        _greeting,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: kS4),
                      Text(
                        'Escull una categoria per començar una entrevista.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ]),
                  ),

                  const SizedBox(height: kS24),

                  // ── Search bar (centered, discrete) ─────────────────
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Cercar categoria...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            filled: true,
                            fillColor: kBgSurface,
                            contentPadding: const EdgeInsets.symmetric(vertical: kS12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(kRadiusMd),
                              borderSide: const BorderSide(color: kBorderSubtle),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(kRadiusMd),
                              borderSide: const BorderSide(color: kAccent, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: kS24),

                  // ── Category cards (horizontally scrollable, max 3 visible) ──
                  _buildCategoryRow(),

                  const SizedBox(height: kS32),

                  // ── Stats row ───────────────────────────────────────
                  if (_recentSessions.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
                      child: _buildStatsRow(),
                    ),
                    const SizedBox(height: kS24),
                  ],

                  // ── Recent sessions ─────────────────────────────────
                  if (_recentSessions.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
                      child: AppSectionHeader(
                        title: 'Sessions recents',
                        trailing: Text(
                          'Veure totes',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: kAccent, fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: kS12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
                      child: Column(
                        children: _recentSessions.map((s) => SessionTile(
                          session: s,
                          onTap: () => context.go('/results/${s.id}'),
                        )).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: kS24),
                ],
              ),
            ),
    );
  }

  // ── Category horizontal scroll row ───────────────────────────────────────
  Widget _buildCategoryRow() {
    final cats = _filteredCategories;
    if (cats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
        child: Center(
          child: Text(
            'Cap categoria coincideix amb la cerca.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    final totalMs = (150 * (cats.length - 1) + 400).clamp(400, 2000);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: AnimatedBuilder(
            animation: _entranceCtrl,
            builder: (context, _) {
              return Column(
                children: List.generate(cats.length, (i) {
                  final cat = cats[i];
                  final desc = _catDescriptions[cat.id] ?? '';
                  final currentMs = _entranceCtrl.value * totalMs;
                  final t = ((currentMs - 150.0 * i) / 400.0).clamp(0.0, 1.0);
                  final val = kCurveEntrance.transform(t);

                  return Opacity(
                    opacity: val,
                    child: Transform.translate(
                      offset: Offset(0, 12.0 * (1.0 - val)),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: kS12),
                        child: _CategoryCard(
                          category: cat,
                          description: desc,
                          onTap: () => context.go(
                            '/interview/${cat.id}?name=${Uri.encodeComponent(cat.name)}',
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kS16, vertical: kS12),
      decoration: BoxDecoration(
        color: kBgSurface,
        borderRadius: BorderRadius.circular(kRadiusMd),
        border: Border.all(color: kBorderSubtle),
        boxShadow: kShadowSm,
      ),
      child: Row(children: [
        const GlowIcon(
          icon: Icons.bar_chart_rounded,
          size: 36,
          iconSize: 20,
        ),
        const SizedBox(width: kS12),
        Text('${_averageScore.toInt()}%',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: kAccent)),
        const SizedBox(width: kS8),
        Text('·  ${_recentSessions.length} sessions',
            style: Theme.of(context).textTheme.bodySmall),
        const Spacer(),
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: Text('Veure historial',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: kAccent, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

}

// ── Category card with hover lift ───────────────────────────────────────────
class _CategoryCard extends StatefulWidget {
  final InterviewCategory category;
  final String description;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.description,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: kDurationFast,
        curve: kCurveHover,
        decoration: BoxDecoration(
          color: kBgSurface,
          borderRadius: BorderRadius.circular(kRadiusMd),
          border: Border.all(
            color: _hovering
                ? kAccent.withValues(alpha: 0.3)
                : kBorderSubtle,
          ),
          boxShadow: _hovering ? kShadowMd : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(kRadiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(kRadiusMd),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kS16,
                vertical: kS12,
              ),
              child: Row(
                children: [
                  GlowIcon(icon: widget.category.icon, size: 36, iconSize: 20),
                  const SizedBox(width: kS16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.category.name,
                            style: Theme.of(context).textTheme.titleSmall),
                        if (widget.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(widget.description,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: kS8),
                  const Icon(Icons.chevron_right_rounded,
                      color: kTextSecondary, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Profile avatar with hover animation + styled popup menu ────────────────
class _ProfileMenuButton extends StatefulWidget {
  final VoidCallback onProfile;
  final VoidCallback onEdit;
  final VoidCallback onLogout;

  const _ProfileMenuButton({
    required this.onProfile,
    required this.onEdit,
    required this.onLogout,
  });

  @override
  State<_ProfileMenuButton> createState() => _ProfileMenuButtonState();
}

class _ProfileMenuButtonState extends State<_ProfileMenuButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverCtrl;
  late final Animation<double> _scaleAnim;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
        CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  void _showMenu() {
    final button = context.findRenderObject() as RenderBox;
    final overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset(0, button.size.height + 8), ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero) + const Offset(0, 8),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusMd),
        side: const BorderSide(color: kBorderSubtle),
      ),
      color: kBgElevated,
      constraints: const BoxConstraints(minWidth: 200),
      items: [
        _menuItem(Icons.person_outline_rounded, 'Perfil', 'profile'),
        _menuItem(Icons.edit_outlined, 'Editar perfil', 'edit'),
        const PopupMenuDivider(height: 1),
        _menuItem(Icons.logout_rounded, 'Tancar sessió', 'logout',
            color: kErrorRed),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'profile':
          widget.onProfile();
        case 'edit':
          widget.onEdit();
        case 'logout':
          widget.onLogout();
      }
    });
  }

  PopupMenuEntry<String> _menuItem(IconData icon, String label, String value,
      {Color? color}) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? kTextSecondary),
          const SizedBox(width: kS12),
          Text(label,
              style: TextStyle(
                  color: color ?? kTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovering = true);
        _hoverCtrl.forward();
      },
      onExit: (_) {
        setState(() => _hovering = false);
        _hoverCtrl.reverse();
      },
      child: GestureDetector(
        onTap: _showMenu,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hovering
                  ? kAccent.withValues(alpha: 0.25)
                  : kAccent.withValues(alpha: 0.15),
              boxShadow: _hovering
                  ? [
                      BoxShadow(
                        color: kAccent.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: const CircleAvatar(
              radius: 17,
              backgroundColor: Colors.transparent,
              child: Icon(Icons.person, color: kAccent, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}