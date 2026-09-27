import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _fast = Duration(milliseconds: 90);

  static ThemeData dark() {
    const seed = Color(0xFF3DDC97);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    final buttons = ButtonStyle(
      animationDuration: _fast,
      splashFactory: InkRipple.splashFactory,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      splashFactory: InkRipple.splashFactory,
      splashColor: const Color(0x333DDC97),
      highlightColor: const Color(0x1A3DDC97),
      scaffoldBackgroundColor: const Color(0xFF101418),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFE8EEF0),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: Color(0xFFE8EEF0),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xFF0D1518),
        indicatorColor: Color(0xFF15241E),
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(style: buttons),
      outlinedButtonTheme: OutlinedButtonThemeData(style: buttons),
      textButtonTheme: TextButtonThemeData(style: buttons),
      iconButtonTheme: IconButtonThemeData(style: buttons),
      segmentedButtonTheme: SegmentedButtonThemeData(style: buttons),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A2026),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
