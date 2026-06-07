import 'package:flutter/material.dart';

class AppTheme {
  // ── Light theme ────────────────────────────────────────────────────────────
  static ThemeData light(Color primary) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(primary: primary);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A2E),
        ),
        iconTheme: IconThemeData(color: primary),
      ),
      cardColor: Colors.white,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          padding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          padding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected) ? primary : null),
        trackColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected)
                ? primary.withOpacity(0.4)
                : null),
      ),
      dividerTheme: const DividerThemeData(
          color: Color(0xFFEEEEEE), thickness: 1, space: 1),
      textTheme: const TextTheme(
        bodyLarge:  TextStyle(color: Color(0xFF1A1A2E)),
        bodyMedium: TextStyle(color: Color(0xFF1A1A2E)),
        bodySmall:  TextStyle(color: Color(0xFF666680)),
      ),
    );
  }

  // ── Dark theme ─────────────────────────────────────────────────────────────
  static ThemeData dark(Color primary) {
    // Lighten the primary slightly for dark mode so it pops on dark bg
    final darkPrimary = Color.lerp(primary, Colors.white, 0.15)!;

    final scheme = ColorScheme.fromSeed(
      seedColor: darkPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: darkPrimary,
      surface: const Color(0xFF1E1E1E),
      background: const Color(0xFF121212),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: darkPrimary),
      ),
      cardColor: const Color(0xFF1E1E1E),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          padding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          side: BorderSide(color: darkPrimary),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          padding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: Color(0xFF3A3A3A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: darkPrimary, width: 2),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected)
                ? darkPrimary
                : null),
        trackColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected)
                ? darkPrimary.withOpacity(0.4)
                : null),
      ),
      dividerTheme: const DividerThemeData(
          color: Color(0xFF2A2A2A), thickness: 1, space: 1),
      textTheme: const TextTheme(
        bodyLarge:  TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall:  TextStyle(color: Color(0xFFAAAAAA)),
      ),
    );
  }

  // ── Legacy static getters (keep for any code still using them) ─────────────
  static ThemeData get lightTheme => light(const Color(0xFF2196F3));
  static ThemeData get darkTheme  => dark(const Color(0xFF2196F3));
}