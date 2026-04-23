import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Light theme colors ──────────────────────────────────────
  static const Color lightPrimary     = Color(0xFF1E3A5F);
  static const Color lightBackground  = Color(0xFFF5F7FA);
  static const Color lightCard        = Color(0xFFFFFFFF);
  static const Color lightText        = Color(0xFF1A1A1A);
  static const Color lightIncome      = Color(0xFF2ECC71);
  static const Color lightExpense     = Color(0xFFE57373);

  // ── Dark theme colors ───────────────────────────────────────
  static const Color darkPrimary      = Color(0xFF4A90E2);
  static const Color darkBackground   = Color(0xFF121212);
  static const Color darkCard         = Color(0xFF1E1E1E);
  static const Color darkText         = Color(0xFFEAEAEA);
  static const Color darkIncome       = Color(0xFF27AE60);
  static const Color darkExpense      = Color(0xFFE57373); // kept soft, same as light

  // ── Shared ──────────────────────────────────────────────────
  static const Color incomeColor   = lightIncome;
  static const Color expenseColor  = lightExpense;

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: lightBackground,
        colorScheme: const ColorScheme.light(
          primary: lightPrimary,
          secondary: lightIncome,
          error: lightExpense,
          surface: lightCard,
          onPrimary: Colors.white,
          onSurface: lightText,
        ),
        textTheme: GoogleFonts.poppinsTextTheme().apply(
          bodyColor: lightText,
          displayColor: lightText,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: lightBackground,
          foregroundColor: lightText,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: lightText,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          color: lightCard,
          shadowColor: lightPrimary.withOpacity(0.08),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFEEF1F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: lightPrimary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: lightPrimary,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: lightPrimary.withOpacity(0.35),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? lightPrimary : Colors.grey),
          trackColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
                  ? lightPrimary.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.3)),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: darkPrimary,
          secondary: darkIncome,
          error: darkExpense,
          surface: darkCard,
          onPrimary: Colors.white,
          onSurface: darkText,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: darkText,
          displayColor: darkText,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: darkBackground,
          foregroundColor: darkText,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: darkText,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          color: darkCard,
          shadowColor: Colors.black.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: darkPrimary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkPrimary,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: darkPrimary.withOpacity(0.35),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? darkPrimary : Colors.grey),
          trackColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
                  ? darkPrimary.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.3)),
        ),
      );
}
