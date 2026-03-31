import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Static brand & semantic constants (theme-independent)
// ══════════════════════════════════════════════════════════════════════════════

const kAccent = Color(0xFF6366F1); // indigo — primary accent
const kAccentTeal = Color(0xFF14B8A6);
const kAccentAmber = Color(0xFFF59E0B);
const kAccentRose = Color(0xFFF43F5E);
const kAccentSky = Color(0xFF38BDF8);

const kScoreGood = Color(0xFF22C55E);
const kScoreMid = Color(0xFFF59E0B);
const kScoreLow = Color(0xFFEF4444);
const kErrorRed = Color(0xFFEF4444);

Color scoreColor(double score) {
  if (score >= 75) return kScoreGood;
  if (score >= 50) return kScoreMid;
  return kScoreLow;
}

// ══════════════════════════════════════════════════════════════════════════════
// Theme-aware colour tokens (accessed via context.colors)
// ══════════════════════════════════════════════════════════════════════════════

class AppColors extends ThemeExtension<AppColors> {
  // Backgrounds
  final Color bgBase;
  final Color bgSurface;
  final Color bgElevated;

  // Glassmorphism
  final Color glassBg;
  final Color glassBorder;
  final Color glassShadow;

  // Text hierarchy
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;

  // Borders
  final Color borderSubtle;
  final Color borderStrong;

  // Dot grid
  final Color dotGridColor;
  final double dotGridOpacity;

  // Decorative glows
  final Color glowBlue;
  final Color glowSlate;

  // Status
  final Color statusDot;

  const AppColors({
    required this.bgBase,
    required this.bgSurface,
    required this.bgElevated,
    required this.glassBg,
    required this.glassBorder,
    required this.glassShadow,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.borderSubtle,
    required this.borderStrong,
    required this.dotGridColor,
    required this.dotGridOpacity,
    required this.glowBlue,
    required this.glowSlate,
    required this.statusDot,
  });

  // ── Light palette ───────────────────────────────────────────────────────
  static const light = AppColors(
    bgBase: Color(0xFFFAFAFA),          // #fafafa — main background
    bgSurface: Color(0xFFF2F2F6),       // between #fafafa and #e4e5f1
    bgElevated: Color(0xFFFFFFFF),      // pure white for elevated cards
    glassBg: Color(0x4DFFFFFF),         // rgba(255,255,255,0.30)
    glassBorder: Color(0x66FFFFFF),     // rgba(255,255,255,0.40)
    glassShadow: Color(0x0A000000),     // rgba(0,0,0,0.04)
    textPrimary: Color(0xFF484B6A),     // #484b6a — main text
    textSecondary: Color(0xFF9394A5),   // #9394a5 — secondary text
    textTertiary: Color(0xFFAAABB8),    // derived — lighter than #9394a5
    textDisabled: Color(0xFFD2D3DB),    // #d2d3db — disabled text
    borderSubtle: Color(0xFFE4E5F1),    // #e4e5f1 — subtle borders
    borderStrong: Color(0xFFD2D3DB),    // #d2d3db — strong borders
    dotGridColor: Color(0xFFD2D3DB),    // #d2d3db — dot grid
    dotGridOpacity: 0.25,               // slightly more visible with lighter base
    glowBlue: Color(0xFFD8DAFE),        // soft purple-blue glow
    glowSlate: Color(0xFFE4E5F1),       // palette purple-gray glow
    statusDot: Color(0xFF9394A5),       // #9394a5 — status indicator
  );

  // ── Dark palette ────────────────────────────────────────────────────────
  static const dark = AppColors(
    bgBase: Color(0xFF101012),
    bgSurface: Color(0xFF1A1A1E),
    bgElevated: Color(0xFF222228),
    glassBg: Color(0x1FFFFFFF),      // rgba(255,255,255,0.12)
    glassBorder: Color(0x1AFFFFFF),   // rgba(255,255,255,0.10)
    glassShadow: Color(0x4D000000),   // rgba(0,0,0,0.30)
    textPrimary: Color(0xFFF5F5F5),
    textSecondary: Color(0xFF94A3B8), // slate-400
    textTertiary: Color(0xFF64748B),  // slate-500
    textDisabled: Color(0xFF475569),  // slate-600
    borderSubtle: Color(0xFF2D2D33),
    borderStrong: Color(0xFF3F3F46),  // zinc-700
    dotGridColor: Color(0xFF3F3F46),
    dotGridOpacity: 0.15,
    glowBlue: Color(0xFF1E3A5F),
    glowSlate: Color(0xFF1E293B),     // slate-800
    statusDot: Color(0xFF94A3B8),     // slate-400
  );

  // ── Gradient helpers (computed from palette) ────────────────────────────

  LinearGradient get gradientAccent => const LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  LinearGradient get gradientAccentSubtle => const LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0x186366F1), Color(0x188B5CF6)],
  );

  LinearGradient get gradientSurface => LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [bgSurface, bgBase],
  );

  LinearGradient get gradientCardBorder => const LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0x406366F1), Color(0x108B5CF6)],
  );

  LinearGradient get gradientCtaGlow => const LinearGradient(
    begin: Alignment.centerLeft, end: Alignment.centerRight,
    colors: [Color(0x333B82F6), Color(0x33A855F7)],
  );

  // ── ThemeExtension overrides ────────────────────────────────────────────

  @override
  AppColors copyWith({
    Color? bgBase, Color? bgSurface, Color? bgElevated,
    Color? glassBg, Color? glassBorder, Color? glassShadow,
    Color? textPrimary, Color? textSecondary, Color? textTertiary,
    Color? textDisabled, Color? borderSubtle, Color? borderStrong,
    Color? dotGridColor, double? dotGridOpacity,
    Color? glowBlue, Color? glowSlate, Color? statusDot,
  }) {
    return AppColors(
      bgBase: bgBase ?? this.bgBase,
      bgSurface: bgSurface ?? this.bgSurface,
      bgElevated: bgElevated ?? this.bgElevated,
      glassBg: glassBg ?? this.glassBg,
      glassBorder: glassBorder ?? this.glassBorder,
      glassShadow: glassShadow ?? this.glassShadow,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      dotGridColor: dotGridColor ?? this.dotGridColor,
      dotGridOpacity: dotGridOpacity ?? this.dotGridOpacity,
      glowBlue: glowBlue ?? this.glowBlue,
      glowSlate: glowSlate ?? this.glowSlate,
      statusDot: statusDot ?? this.statusDot,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bgBase: Color.lerp(bgBase, other.bgBase, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      glassBg: Color.lerp(glassBg, other.glassBg, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassShadow: Color.lerp(glassShadow, other.glassShadow, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      dotGridColor: Color.lerp(dotGridColor, other.dotGridColor, t)!,
      dotGridOpacity: dotGridOpacity + (other.dotGridOpacity - dotGridOpacity) * t,
      glowBlue: Color.lerp(glowBlue, other.glowBlue, t)!,
      glowSlate: Color.lerp(glowSlate, other.glowSlate, t)!,
      statusDot: Color.lerp(statusDot, other.statusDot, t)!,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Convenience extension for easy access: context.colors.bgBase
// ══════════════════════════════════════════════════════════════════════════════

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
