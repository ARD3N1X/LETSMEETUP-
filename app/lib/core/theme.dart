import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'palette.dart';

/// Dodatkowe kolory semantyczne, których nie ma w [ColorScheme].
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.card,
    required this.outsideMonthCell,
    required this.gridLine,
    required this.muted,
    required this.danger,
    required this.dangerSoft,
    required this.shadow,
  });

  final Color background;
  final Color card;
  final Color outsideMonthCell;
  final Color gridLine;
  final Color muted;
  final Color danger;
  final Color dangerSoft;
  final Color shadow;

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      outsideMonthCell: Color.lerp(outsideMonthCell, other.outsideMonthCell, t)!,
      gridLine: Color.lerp(gridLine, other.gridLine, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension AppThemeX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  ColorScheme get scheme => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}

class AppTheme {
  AppTheme._();

  /// Pastelowy akcent zamieniony na kolor przycisków o wystarczającym kontraście.
  static Color primaryFrom(Color accent, Brightness brightness) {
    final hsl = HSLColor.fromColor(accent);
    final saturation = hsl.saturation < 0.35 ? hsl.saturation : (hsl.saturation * 0.95).clamp(0.45, 0.9);
    final lightness = brightness == Brightness.light ? 0.58 : 0.66;
    return hsl.withSaturation(saturation.toDouble()).withLightness(lightness).toColor();
  }

  /// [googleFonts] = false w testach (brak dostępu do sieci).
  static ThemeData build(Brightness brightness, Color accent, {bool googleFonts = true}) {
    final isDark = brightness == Brightness.dark;
    final primary = primaryFrom(accent, brightness);
    final base = ColorScheme.fromSeed(seedColor: accent, brightness: brightness);

    final scheme = base.copyWith(
      primary: primary,
      onPrimary: Palette.onColor(primary),
      primaryContainer: accent.withValues(alpha: isDark ? 0.22 : 0.16),
      onPrimaryContainer: Palette.withLightness(primary, isDark ? 0.8 : 0.32),
      surface: isDark ? const Color(0xFF121212) : const Color(0xFFF6F7F9),
      onSurface: isDark ? const Color(0xFFECECEF) : const Color(0xFF1B1B1F),
      surfaceContainerHighest: isDark ? const Color(0xFF262629) : const Color(0xFFEFF0F3),
      onSurfaceVariant: isDark ? const Color(0xFFA9A9B2) : const Color(0xFF6B6F7B),
      outline: isDark ? const Color(0xFF3A3A40) : const Color(0xFFE1E3E8),
      outlineVariant: isDark ? const Color(0xFF2E2E33) : const Color(0xFFE9EAEE),
      error: const Color(0xFFE5484D),
    );

    final colors = AppColors(
      background: scheme.surface,
      card: isDark ? const Color(0xFF1E1E21) : Colors.white,
      outsideMonthCell: isDark ? const Color(0xFF19191B) : const Color(0xFFECEDF2),
      gridLine: isDark ? const Color(0xFF2C2C31) : const Color(0xFFE3E5EA),
      muted: scheme.onSurfaceVariant,
      danger: const Color(0xFFE5484D),
      dangerSoft: isDark ? const Color(0xFF3A1F22) : const Color(0xFFFFEEF0),
      shadow: isDark ? Colors.black.withValues(alpha: 0.4) : const Color(0xFF8A93A6).withValues(alpha: 0.14),
    );

    final baseText = ThemeData(brightness: brightness).textTheme;
    final textTheme = (googleFonts ? GoogleFonts.plusJakartaSansTextTheme(baseText) : baseText)
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    final roundedField = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: scheme.outline),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      textTheme: textTheme,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: roundedField,
        enabledBorder: roundedField,
        focusedBorder: roundedField.copyWith(borderSide: BorderSide(color: primary, width: 1.6)),
        errorBorder: roundedField.copyWith(borderSide: BorderSide(color: scheme.error)),
        focusedErrorBorder: roundedField.copyWith(borderSide: BorderSide(color: scheme.error, width: 1.6)),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.8)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Palette.onColor(primary),
        shape: const CircleBorder(),
        elevation: 6,
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outline),
        backgroundColor: colors.card,
        selectedColor: primary,
        labelStyle: textTheme.labelLarge,
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(color: Palette.onColor(primary)),
        checkmarkColor: Palette.onColor(primary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected) ? primary : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: states.contains(WidgetState.selected) ? primary : scheme.onSurfaceVariant),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? primary : null),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
    );
  }
}
