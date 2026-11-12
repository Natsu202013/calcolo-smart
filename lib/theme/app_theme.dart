import 'package:flutter/material.dart';

/// Palette e temi di Calcolo Smart.
class AppColors {
  const AppColors._();

  // Dark
  static const Color darkBg = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF141C2E);
  static const Color darkSurfaceHigh = Color(0xFF1D2740);
  static const Color darkDisplay = Color(0xFF0E1626);

  // Light
  static const Color lightBg = Color(0xFFF4F6FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceHigh = Color(0xFFE9EDF6);
  static const Color lightDisplay = Color(0xFFFFFFFF);

  // Accenti
  static const Color indigo = Color(0xFF5B6BFF);
  static const Color indigoDeep = Color(0xFF3D4BE8);
  static const Color violet = Color(0xFF9B6BFF);
  static const Color mint = Color(0xFF2ED3A5);
  static const Color coral = Color(0xFFFF6E7A);
  static const Color amber = Color(0xFFFFB44D);

  static const List<Color> equalsGradient = <Color>[indigo, violet];
}

/// Estensione con i colori semantici dei tasti per entrambi i temi.
@immutable
class CalcPalette extends ThemeExtension<CalcPalette> {
  final Color numberBg;
  final Color numberFg;
  final Color functionBg;
  final Color functionFg;
  final Color operatorBg;
  final Color operatorFg;
  final Color accentFg;
  final Color displayBg;
  final Color expressionFg;
  final Color resultFg;
  final Color surfaceBg;
  final Color chipBg;

  const CalcPalette({
    required this.numberBg,
    required this.numberFg,
    required this.functionBg,
    required this.functionFg,
    required this.operatorBg,
    required this.operatorFg,
    required this.accentFg,
    required this.displayBg,
    required this.expressionFg,
    required this.resultFg,
    required this.surfaceBg,
    required this.chipBg,
  });

  static const CalcPalette dark = CalcPalette(
    numberBg: AppColors.darkSurfaceHigh,
    numberFg: Color(0xFFF2F5FF),
    functionBg: Color(0xFF19233A),
    functionFg: Color(0xFFA8B6D9),
    operatorBg: Color(0xFF243254),
    operatorFg: AppColors.indigo,
    accentFg: Colors.white,
    displayBg: AppColors.darkDisplay,
    expressionFg: Color(0xFF8A9AC2),
    resultFg: Colors.white,
    surfaceBg: AppColors.darkSurface,
    chipBg: Color(0xFF243254),
  );

  static const CalcPalette light = CalcPalette(
    numberBg: AppColors.lightSurface,
    numberFg: Color(0xFF141B2D),
    functionBg: AppColors.lightSurfaceHigh,
    functionFg: Color(0xFF5A6885),
    operatorBg: Color(0xFFE2E8FA),
    operatorFg: AppColors.indigoDeep,
    accentFg: Colors.white,
    displayBg: AppColors.lightDisplay,
    expressionFg: Color(0xFF7A87A3),
    resultFg: Color(0xFF141B2D),
    surfaceBg: AppColors.lightSurface,
    chipBg: Color(0xFFE2E8FA),
  );

  @override
  CalcPalette copyWith({
    Color? numberBg,
    Color? numberFg,
    Color? functionBg,
    Color? functionFg,
    Color? operatorBg,
    Color? operatorFg,
    Color? accentFg,
    Color? displayBg,
    Color? expressionFg,
    Color? resultFg,
    Color? surfaceBg,
    Color? chipBg,
  }) {
    return CalcPalette(
      numberBg: numberBg ?? this.numberBg,
      numberFg: numberFg ?? this.numberFg,
      functionBg: functionBg ?? this.functionBg,
      functionFg: functionFg ?? this.functionFg,
      operatorBg: operatorBg ?? this.operatorBg,
      operatorFg: operatorFg ?? this.operatorFg,
      accentFg: accentFg ?? this.accentFg,
      displayBg: displayBg ?? this.displayBg,
      expressionFg: expressionFg ?? this.expressionFg,
      resultFg: resultFg ?? this.resultFg,
      surfaceBg: surfaceBg ?? this.surfaceBg,
      chipBg: chipBg ?? this.chipBg,
    );
  }

  @override
  CalcPalette lerp(ThemeExtension<CalcPalette>? other, double t) {
    if (other is! CalcPalette) return this;
    return CalcPalette(
      numberBg: Color.lerp(numberBg, other.numberBg, t)!,
      numberFg: Color.lerp(numberFg, other.numberFg, t)!,
      functionBg: Color.lerp(functionBg, other.functionBg, t)!,
      functionFg: Color.lerp(functionFg, other.functionFg, t)!,
      operatorBg: Color.lerp(operatorBg, other.operatorBg, t)!,
      operatorFg: Color.lerp(operatorFg, other.operatorFg, t)!,
      accentFg: Color.lerp(accentFg, other.accentFg, t)!,
      displayBg: Color.lerp(displayBg, other.displayBg, t)!,
      expressionFg: Color.lerp(expressionFg, other.expressionFg, t)!,
      resultFg: Color.lerp(resultFg, other.resultFg, t)!,
      surfaceBg: Color.lerp(surfaceBg, other.surfaceBg, t)!,
      chipBg: Color.lerp(chipBg, other.chipBg, t)!,
    );
  }
}

/// Helper per accedere rapidamente alla palette dal widget tree.
extension CalcPaletteX on BuildContext {
  CalcPalette get calc =>
      Theme.of(this).extension<CalcPalette>() ?? CalcPalette.dark;
}

class AppTheme {
  const AppTheme._();

  static ThemeData _base({
    required Brightness brightness,
    required CalcPalette palette,
  }) {
    final bool isDark = brightness == Brightness.dark;
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.indigo,
      brightness: brightness,
      primary: AppColors.indigo,
      secondary: AppColors.violet,
      surface: palette.surfaceBg,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      extensions: <ThemeExtension<dynamic>>[palette],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: palette.resultFg,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: palette.functionFg),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? AppColors.darkSurfaceHigh
            : const Color(0xFF1F2733),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surfaceBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  static ThemeData get dark =>
      _base(brightness: Brightness.dark, palette: CalcPalette.dark);
  static ThemeData get light =>
      _base(brightness: Brightness.light, palette: CalcPalette.light);
}
