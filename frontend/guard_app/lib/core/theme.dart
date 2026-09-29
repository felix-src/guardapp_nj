import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Green, brown, and tan: the app's palette. Tuned for vibrance while
/// keeping WCAG AA contrast (4.5:1) for white and tan text on [heroGradient].
abstract final class GuardColors {
  static const forest = Color(0xFF1B5E32);
  static const olive = Color(0xFF2C6420);
  static const brown = Color(0xFF7A4418);
  static const saddle = Color(0xFF9A5A22);
  static const tan = Color(0xFFF2C97E);
  static const sand = Color(0xFFF0E7D6);
  static const ink = Color(0xFF1A1712);

  /// Headers and the sign-in background: forest -> olive -> brown.
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [forest, olive, brown],
  );

  /// Icon badges, in the order home tiles use them.
  static const badgeGradients = [
    LinearGradient(colors: [Color(0xFF2E8B47), forest]),
    LinearGradient(colors: [Color(0xFFA8672C), Color(0xFF6E3B14)]),
    LinearGradient(colors: [Color(0xFFC68A38), Color(0xFF8C5520)]),
    LinearGradient(colors: [Color(0xFF4C8A2E), olive]),
    LinearGradient(colors: [Color(0xFF8B5A2B), Color(0xFF5A3312)]),
    LinearGradient(colors: [Color(0xFF3D9A55), Color(0xFF236B34)]),
  ];
}

ThemeData buildGuardTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;

  final scheme = ColorScheme.fromSeed(
    seedColor: GuardColors.forest,
    brightness: brightness,
    primary: dark ? const Color(0xFF7FCF8A) : GuardColors.forest,
    onPrimary: dark ? const Color(0xFF0C2413) : Colors.white,
    secondary: dark ? GuardColors.tan : GuardColors.brown,
    onSecondary: dark ? GuardColors.ink : Colors.white,
    tertiary: dark ? const Color(0xFFF5D9A8) : GuardColors.saddle,
    surface: dark ? const Color(0xFF221F1A) : Colors.white,
    onSurface: dark ? const Color(0xFFF4EEE4) : GuardColors.ink,
  );
  final background = dark ? const Color(0xFF100E0B) : GuardColors.sand;
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    // iPhone-first: Cupertino transitions, bounce scrolling, iOS back chevrons
    // and centered titles on every platform (incl. the Android emulator).
    platform: TargetPlatform.iOS,
    scaffoldBackgroundColor: background,
  );

  return base.copyWith(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    textTheme: base.textTheme.copyWith(
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: rounded,
      clipBehavior: Clip.antiAlias,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.onSurface.withValues(alpha: 0.08),
      space: 1,
      thickness: 0.5,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF2A2723) : const Color(0xFFF7F4EF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        shape: const StadiumBorder(),
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.secondary,
      foregroundColor: scheme.onSecondary,
      shape: const StadiumBorder(),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: rounded,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      shape: Border(),
      collapsedShape: Border(),
    ),
    cupertinoOverrideTheme: CupertinoThemeData(primaryColor: scheme.primary),
  );
}
