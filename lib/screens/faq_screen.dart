import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart' show kFontSerif;
import '../widgets/dot_grid_background.dart';
import '../widgets/faq_accordion.dart';

/// Standalone FAQ page accessible from the landing screen.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DotGridBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: kPagePadding, vertical: kS12),
                child: Row(
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => context.go('/landing'),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                              color: context.colors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Entrevista't",
                              style: TextStyle(
                                fontFamily: kFontSerif,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: context.colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable FAQ content ─────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: kS32, bottom: kS48),
                    child: Center(
                      child: FaqAccordionSection(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
