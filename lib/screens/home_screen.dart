import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../main.dart' show EntrevistatApp;
import '../models/interview_models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart' show kFontSans;
// TODO: Uncomment when recent sessions section is re-enabled
// import '../widgets/app_section_header.dart';
import '../widgets/dot_grid_background.dart';
// GlassContainer currently unused after stats row redesign
// import '../widgets/glass_container.dart';
import '../widgets/glow_icon.dart';
// TODO: Uncomment when recent sessions section is re-enabled
// import '../widgets/session_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {

  List<InterviewCategory> _categories = [];
  List<InterviewCategory> _filteredCategories = [];
  List<InterviewSession> _recentSessions = [];
  bool _loading = true;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;
  bool _imagesPrecached = false;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  late final AnimationController _entranceCtrl;

  String get _greeting {
    final hour = DateTime.now().hour;
    final name = ApiService.userName ?? 'Usuari';
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
    _scrollController.addListener(_updateScrollArrows);
    _load();
    _searchController.addListener(_filterCategories);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPrecached) {
      _imagesPrecached = true;
      precacheImage(
        const AssetImage('assets/images/logo_entrevistat.png'), context);
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Strips diacritics for accent-insensitive search.
  static String _removeDiacritics(String s) {
    const withDiacritics =    'àáâãäåèéêëìíîïòóôõöùúûüýÿñçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÝŸÑÇ';
    const withoutDiacritics = 'aaaaaaeeeeiiiioooooouuuuyynçAAAAAAEEEEIIIIOOOOOUUUUYYNC';
    return s.split('').map((c) {
      final i = withDiacritics.indexOf(c);
      return i >= 0 ? withoutDiacritics[i] : c;
    }).join();
  }

  void _filterCategories() {
    final q = _removeDiacritics(_searchController.text.toLowerCase().trim());
    final previous = _filteredCategories;
    List<InterviewCategory> updated;
    if (q.isEmpty) {
      updated = _allCats;
    } else {
      updated = _allCats
          .where((c) =>
              _removeDiacritics(c.name.toLowerCase()).contains(q))
          .toList();
    }
    if (updated.length == previous.length &&
        identical(updated, previous) == false &&
        q.isEmpty &&
        _searchController.text.isEmpty) {
      return;
    }
    final changed = updated.length != previous.length ||
        !_listsEqual(updated, previous);
    setState(() {
      _filteredCategories = updated;
    });
    if (changed) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      _restartEntrance(_filteredCategories.length);
    }
  }

  static bool _listsEqual(
      List<InterviewCategory> a, List<InterviewCategory> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  void _updateScrollArrows() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final left = pos.pixels > pos.minScrollExtent + 1;
    final right = pos.pixels < pos.maxScrollExtent - 1;
    if (left != _canScrollLeft || right != _canScrollRight) {
      setState(() {
        _canScrollLeft = left;
        _canScrollRight = right;
      });
    }
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
    final completed = _recentSessions.where((s) => s.overallScore != null).toList();
    if (completed.isEmpty) return 0;
    return completed.map((s) => s.overallScore!).reduce((a, b) => a + b) / completed.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgBase,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = MediaQuery.of(context).size.width < 600;
            if (isMobile) {
              return Padding(
                padding: const EdgeInsets.only(left: kS12),
                child: _ThemeToggleButton(),
              );
            }
            return const SizedBox(width: 48);
          },
        ),
        title: Center(
          child: GestureDetector(
            onTap: () => context.go('/landing'),
            child: Image.asset(
              'assets/images/logo_entrevistat.png',
              width: 28, height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.play_circle_filled,
                size: 28,
                color: kAccent,
              ),
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
      body: DotGridBackground(
        showGlows: true,
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: kAccent,
              backgroundColor: context.colors.bgSurface,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: kS16),
                children: [
                  // ── Welcome text (centered) ─────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
                    child: Column(children: [
                      Text(
                        _greeting,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontFamily: kFontSans,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: kS4),
                      Text(
                        'Escull una categoria per començar una entrevista.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: kFontSans,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ]),
                  ),

                  const SizedBox(height: kS16),

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
                            fillColor: context.colors.bgSurface,
                            contentPadding: const EdgeInsets.symmetric(vertical: kS12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(kRadiusMd),
                              borderSide: BorderSide(color: context.colors.borderSubtle),
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

                  const SizedBox(height: kS16),

                  // ── Stats row (above grid) ─────────────────────────
                  if (_recentSessions.isNotEmpty) ...[
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
                          child: _buildStatsRow(),
                        ),
                      ),
                    ),
                    const SizedBox(height: kS16),
                  ],

                  // ── Category cards (responsive mosaic grid) ──────────
                  _buildCategoryGrid(),

                  const SizedBox(height: kS16),

                  // TODO: Uncomment when ready to show recent sessions
                  // ── Recent sessions ─────────────────────────────────
                  // if (_recentSessions.isNotEmpty) ...[
                  //   Padding(
                  //     padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
                  //     child: AppSectionHeader(
                  //       title: 'Sessions recents',
                  //       trailing: Text(
                  //         'Veure totes',
                  //         style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  //           color: kAccent, fontWeight: FontWeight.w600,
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  //   const SizedBox(height: kS12),
                  //   Padding(
                  //     padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
                  //     child: Column(
                  //       children: _recentSessions.map((s) => SessionTile(
                  //         session: s,
                  //         onTap: () => context.go('/results/${s.id}'),
                  //       )).toList(),
                  //     ),
                  //   ),
                  // ],
                  const SizedBox(height: kS12),
                ],
              ),
            ),
      ),
    );
  }

  // ── Category grid (2 rows, horizontal column-snap scroll) ─────────────────
  Widget _buildCategoryGrid() {
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
    // Per-item stagger scales with clamped duration so every item
    // reaches full opacity when the animation completes.
    final stagger = cats.length <= 1 ? 0.0 : (totalMs - 400) / (cats.length - 1);
    const rows = 2;
    const spacing = kS16;
    const hoverOverflow = 6.0;
    const arrowWidth = 36.0;

    final colCount = (cats.length / rows).ceil();

    return AnimatedBuilder(
      animation: _entranceCtrl,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;

            // Responsive: 2 columns on mobile, 4 on desktop.
            final visibleCols = screenWidth < 600 ? 2 : 4;
            final showArrows = colCount > visibleCols && screenWidth >= 600;

            // Available space for the grid area (between arrows).
            final arrowSpace = showArrows ? arrowWidth * 2 : 0.0;
            final maxGridContent = 720.0;
            final availableForGrid =
                (screenWidth - 2 * kPagePadding - arrowSpace)
                    .clamp(0.0, maxGridContent);

            // Card width so that visibleCols columns fit exactly in
            // the available space (gridWidth == availableForGrid).
            final cardWidth = availableForGrid / visibleCols - spacing;
            final cardHeight = cardWidth * 1.15;
            final columnExtent = cardWidth + spacing;

            // gridWidth == visibleCols * columnExtent == availableForGrid.
            final gridWidth = availableForGrid;
            final gridHeight =
                cardHeight * rows + spacing + hoverOverflow * 2;

            // Schedule arrow state update after layout.
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _updateScrollArrows());

            final showMobileHint =
                !showArrows && colCount > visibleCols;

            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: kPagePadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Left arrow
                      if (showArrows)
                        _GridArrow(
                          icon: Icons.chevron_left_rounded,
                          visible: _canScrollLeft,
                          onTap: () => _scrollController.animateTo(
                            (_scrollController.offset - columnExtent)
                                .clamp(
                                    _scrollController
                                        .position.minScrollExtent,
                                    _scrollController
                                        .position.maxScrollExtent),
                            duration: kDurationNormal,
                            curve: kCurveEntrance,
                          ),
                        ),

                      // Grid
                      SizedBox(
                        width: gridWidth,
                        height: gridHeight,
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context)
                              .copyWith(scrollbars: false),
                          child: ListView.builder(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            physics: _ColumnSnapScrollPhysics(
                                columnExtent: columnExtent,
                                trailingGap: spacing,
                                parent: const ClampingScrollPhysics()),
                            padding: EdgeInsets.zero,
                            itemCount: colCount,
                            itemBuilder: (context, colIndex) {
                              final isLastCol = colIndex == colCount - 1;
                              return SizedBox(
                                width: isLastCol ? cardWidth : columnExtent,
                                child: Column(
                                children: [
                                  SizedBox(height: hoverOverflow),
                                  ...List.generate(rows, (rowIndex) {
                                    final catIndex =
                                        colIndex * rows + rowIndex;
                                    if (catIndex >= cats.length) {
                                      return SizedBox(
                                        width: cardWidth,
                                        height: cardHeight,
                                      );
                                    }
                                    final cat = cats[catIndex];
                                    final desc =
                                        cat.description ?? '';
                                    final currentMs =
                                        _entranceCtrl.value * totalMs;
                                    final t = ((currentMs -
                                                stagger * catIndex) /
                                            400.0)
                                        .clamp(0.0, 1.0);
                                    final val =
                                        kCurveEntrance.transform(t);

                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: rowIndex < rows - 1
                                            ? spacing
                                            : 0,
                                      ),
                                      child: Opacity(
                                        opacity: val,
                                        child: Transform.translate(
                                          offset: Offset(
                                              0, 12.0 * (1.0 - val)),
                                          child: SizedBox(
                                            width: cardWidth,
                                            height: cardHeight,
                                            child: _CategoryCard(
                                              category: cat,
                                              description: desc,
                                              onTap: () => context.go(
                                                '/interview/${cat.id}?name=${Uri.encodeComponent(cat.name)}',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Right arrow
                      if (showArrows)
                        _GridArrow(
                          icon: Icons.chevron_right_rounded,
                          visible: _canScrollRight,
                          onTap: () => _scrollController.animateTo(
                            (_scrollController.offset + columnExtent)
                                .clamp(
                                    _scrollController
                                        .position.minScrollExtent,
                                    _scrollController
                                        .position.maxScrollExtent),
                            duration: kDurationNormal,
                            curve: kCurveEntrance,
                          ),
                        ),
                    ],
                  ),
                  if (showMobileHint)
                    Padding(
                      padding: const EdgeInsets.only(top: kS8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.swipe_rounded,
                              size: 14,
                              color: context.colors.textTertiary),
                          const SizedBox(width: kS4),
                          Text(
                            'Llisca per veure més categories',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontSize: 12,
                                  color: context.colors.textTertiary,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatsRow() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kAccent.withValues(alpha: 0.08),
            kAccent.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(kRadiusLg),
        border: Border.all(color: kAccent.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: kS16, vertical: kS16),
      child: Row(children: [
        const GlowIcon(
          icon: Icons.bar_chart_rounded,
          size: 36,
          iconSize: 20,
        ),
        const SizedBox(width: kS12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Puntuació Mitjana',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.colors.textSecondary,
                  )),
              const SizedBox(height: kS4),
              Text('${_averageScore.toInt()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: kAccent, fontWeight: FontWeight.bold,
                  )),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${_recentSessions.length} sessions',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colors.textSecondary,
                )),
            const SizedBox(height: kS4),
            GestureDetector(
              onTap: () => context.go('/profile'),
              child: Text('Veure historial',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: kAccent, fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ),
      ]),
    );
  }

}

// ── Category mosaic tile with hover effect ──────────────────────────────────
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
    final colors = context.colors;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: kDurationFast,
          curve: kCurveHover,
          padding: const EdgeInsets.symmetric(vertical: kS20, horizontal: kS12),
          transform: _hovering
              ? (Matrix4.identity()..scale(1.02))
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(kRadiusLg),
            border: Border.all(
              color: _hovering
                  ? kAccent.withValues(alpha: 0.25)
                  : colors.borderStrong,
            ),
            boxShadow: _hovering ? kShadowMd : kShadowSm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlowIcon(
                icon: widget.category.icon,
                size: 52,
                iconSize: 26,
                glow: _hovering,
              ),
              const SizedBox(height: kS12),
              Text(
                widget.category.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.description.isNotEmpty) ...[
                const SizedBox(height: kS4),
                Text(
                  widget.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: colors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Arrow button for category grid navigation ──────────────────────────────
class _GridArrow extends StatelessWidget {
  final IconData icon;
  final bool visible;
  final VoidCallback onTap;

  const _GridArrow({
    required this.icon,
    required this.visible,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.3,
      duration: kDurationFast,
      child: MouseRegion(
        cursor:
            visible ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: visible ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: kS4),
            child: Icon(
              icon,
              size: 28,
              color: context.colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── AppBar theme toggle button (mobile only) ───────────────────────────────
class _ThemeToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => EntrevistatApp.themeNotifier.toggle(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kAccent.withValues(alpha: 0.08),
        ),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          size: 16,
          color: context.colors.textSecondary,
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
        side: BorderSide(color: context.colors.borderSubtle),
      ),
      color: context.colors.bgSurface,
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
          Icon(icon, size: 18, color: color ?? context.colors.textSecondary),
          const SizedBox(width: kS12),
          Text(label,
              style: TextStyle(
                  color: color ?? context.colors.textPrimary,
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
                  ? kAccent.withValues(alpha: 0.12)
                  : kAccent.withValues(alpha: 0.08),
              boxShadow: _hovering
                  ? [
                      BoxShadow(
                        color: kAccent.withValues(alpha: 0.15),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: const CircleAvatar(
              radius: 17,
              backgroundColor: Colors.transparent,
              child: _ProfileAvatar(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small avatar that shows the user's profile picture if available.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    final photoUrl = ApiService.userPhotoUrl;
    if (photoUrl != null) {
      return CircleAvatar(
        radius: 17,
        backgroundImage: NetworkImage('${ApiService.baseUrl}$photoUrl'),
        backgroundColor: Colors.transparent,
      );
    }
    return const Icon(Icons.person, color: kAccent, size: 18);
  }
}

// ── Scroll physics that snaps to column boundaries ─────────────────────────
class _ColumnSnapScrollPhysics extends ScrollPhysics {
  final double columnExtent;
  final double trailingGap;

  const _ColumnSnapScrollPhysics({
    required this.columnExtent,
    this.trailingGap = 0,
    super.parent,
  });

  @override
  _ColumnSnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _ColumnSnapScrollPhysics(
      columnExtent: columnExtent,
      trailingGap: trailingGap,
      parent: buildParent(ancestor),
    );
  }

  double _snapToColumn(double offset) {
    return (offset / columnExtent).round() * columnExtent;
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final effectiveMax = position.maxScrollExtent;
    if ((velocity.abs() < toleranceFor(position).velocity) &&
        (position.pixels - _snapToColumn(position.pixels)).abs() <
            toleranceFor(position).distance) {
      return null;
    }

    final target = _snapToColumn(
      velocity > 0
          ? position.pixels + columnExtent * 0.5
          : velocity < 0
              ? position.pixels - columnExtent * 0.5
              : position.pixels,
    ).clamp(position.minScrollExtent, effectiveMax);

    if (target == position.pixels) return null;

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: toleranceFor(position),
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}