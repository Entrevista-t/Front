import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// Font family constants — loaded from assets/fonts/.
const kFontSerif = 'Gambetta';
const kFontSans = 'Satoshi';

class AppTheme {
  AppTheme._();

  // ── Shared text styles ──────────────────────────────────────────────────
  static const _serifStyle = TextStyle(fontFamily: kFontSerif, fontStyle: FontStyle.normal);
  static const _sansStyle = TextStyle(fontFamily: kFontSans, fontStyle: FontStyle.normal);

  // ── Light theme ─────────────────────────────────────────────────────────
  static ThemeData light() => _build(Brightness.light, AppColors.light);

  // ── Dark theme ──────────────────────────────────────────────────────────
  static ThemeData dark() => _build(Brightness.dark, AppColors.dark);

  // ── Builder ─────────────────────────────────────────────────────────────
  static ThemeData _build(Brightness brightness, AppColors c) {
    final isDark = brightness == Brightness.dark;
    final base = isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: kAccent,
      brightness: brightness,
    ).copyWith(
      primary: kAccent,
      surface: c.bgSurface,
      onSurface: c.textPrimary,
      onPrimary: Colors.white,
      secondary: kAccent,
      onSecondary: Colors.white,
      error: kErrorRed,
      onError: Colors.white,
    );

    final textTheme = base.textTheme.copyWith(
      displayLarge: _serifStyle.copyWith(
        fontSize: 48, fontWeight: FontWeight.w500,
        color: c.textPrimary, letterSpacing: -0.5, height: 1.1,
      ),
      displayMedium: _serifStyle.copyWith(
        fontSize: 36, fontWeight: FontWeight.w500,
        color: c.textPrimary, letterSpacing: -0.3, height: 1.15,
      ),
      headlineMedium: _serifStyle.copyWith(
        fontSize: 28, fontWeight: FontWeight.w500,
        color: c.textPrimary, letterSpacing: -0.3, height: 1.2,
      ),
      headlineSmall: _serifStyle.copyWith(
        fontSize: 22, fontWeight: FontWeight.w500,
        color: c.textPrimary, height: 1.25,
      ),
      titleLarge: _sansStyle.copyWith(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: c.textPrimary, letterSpacing: -0.2,
      ),
      titleMedium: _sansStyle.copyWith(
        fontSize: 16, fontWeight: FontWeight.w600,
        color: c.textPrimary,
      ),
      titleSmall: _sansStyle.copyWith(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: c.textPrimary,
      ),
      bodyLarge: _sansStyle.copyWith(
        fontSize: 16, fontWeight: FontWeight.w400,
        color: c.textPrimary, height: 1.6,
      ),
      bodyMedium: _sansStyle.copyWith(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: c.textPrimary, height: 1.5,
      ),
      bodySmall: _sansStyle.copyWith(
        fontSize: 13, fontWeight: FontWeight.w400,
        color: c.textSecondary, height: 1.5,
      ),
      labelLarge: _sansStyle.copyWith(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: c.textPrimary,
      ),
      labelSmall: _sansStyle.copyWith(
        fontSize: 11, fontWeight: FontWeight.w500,
        color: c.textSecondary, letterSpacing: 0.4,
      ),
    );

    final pillShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kRadiusFull),
    );

    // CTA button colours: dark bg in light mode, lighter surface in dark mode
    final ctaBg = isDark ? const Color(0xFFF5F5F5) : c.textPrimary;
    final ctaFg = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return base.copyWith(
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: c.bgBase,
      extensions: [c],

      appBarTheme: AppBarTheme(
        backgroundColor: c.bgBase,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: _sansStyle.copyWith(
          fontSize: 17, fontWeight: FontWeight.w600,
          color: c.textPrimary,
        ),
        iconTheme: IconThemeData(color: c.textPrimary),
        actionsIconTheme: IconThemeData(color: c.textSecondary),
        shape: Border(
          bottom: BorderSide(color: c.borderSubtle),
        ),
      ),

      drawerTheme: DrawerThemeData(
        backgroundColor: c.bgSurface,
        scrimColor: Colors.transparent,
      ),

      cardTheme: CardThemeData(
        color: c.bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusMd),
          side: BorderSide(color: c.borderSubtle),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ctaBg,
          foregroundColor: ctaFg,
          disabledBackgroundColor: ctaBg.withValues(alpha: 0.4),
          disabledForegroundColor: ctaFg.withValues(alpha: 0.5),
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          shape: pillShape,
          textStyle: _sansStyle.copyWith(
            fontSize: 15, fontWeight: FontWeight.w500,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return ctaFg.withValues(alpha: 0.1);
            }
            if (states.contains(WidgetState.pressed)) {
              return ctaFg.withValues(alpha: 0.15);
            }
            return null;
          }),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ctaBg,
          foregroundColor: ctaFg,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          shape: pillShape,
          textStyle: _sansStyle.copyWith(
            fontSize: 15, fontWeight: FontWeight.w500,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textSecondary,
          side: BorderSide(color: c.borderSubtle),
          minimumSize: const Size(double.infinity, 48),
          shape: pillShape,
          textStyle: _sansStyle.copyWith(
            fontSize: 15, fontWeight: FontWeight.w500,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return c.bgSurface.withValues(alpha: isDark ? 0.1 : 1.0);
            }
            if (states.contains(WidgetState.pressed)) {
              return c.borderSubtle.withValues(alpha: isDark ? 0.15 : 1.0);
            }
            return null;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return BorderSide(color: c.borderStrong);
            }
            return BorderSide(color: c.borderSubtle);
          }),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: kAccent,
          textStyle: _sansStyle.copyWith(
            fontSize: 14, fontWeight: FontWeight.w600,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return kAccent.withValues(alpha: 0.06);
            }
            return null;
          }),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.bgSurface,
        hintStyle: _sansStyle.copyWith(
          color: c.textDisabled, fontSize: 14,
        ),
        labelStyle: _sansStyle.copyWith(
          color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w500,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusMd),
          borderSide: BorderSide(color: c.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusMd),
          borderSide: const BorderSide(color: kAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusMd),
          borderSide: const BorderSide(color: kErrorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusMd),
          borderSide: const BorderSide(color: kErrorRed, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: kS16, vertical: kS16,
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? kAccent : Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: c.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      dividerTheme: DividerThemeData(
        color: c.borderSubtle,
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusMd),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.textPrimary,
        contentTextStyle: _sansStyle.copyWith(
          color: isDark ? Colors.black : Colors.white, fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: kAccent,
      ),

      iconTheme: IconThemeData(
        color: c.textSecondary,
        size: 20,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.textPrimary,
          borderRadius: BorderRadius.circular(kRadiusSm),
        ),
        textStyle: _sansStyle.copyWith(
          color: isDark ? Colors.black : Colors.white, fontSize: 12,
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: c.bgSurface,
        elevation: 8,
        shadowColor: const Color(0x1A000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusMd),
          side: BorderSide(color: c.borderSubtle),
        ),
      ),
    );
  }
}
