import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Palette theo ảnh thiết kế: Đỏ đậm + Trắng sạch ──────────────────
  static const primaryColor    = Color(0xFFD32027); // Đỏ đậm chủ đạo
  static const primaryDark     = Color(0xFFB71C1C); // Hover / Pressed
  static const primaryLight    = Color(0xFFFF5252); // Accent nhẹ
  static const accentColor     = Color(0xFF4CAF50); // Green accent (success)
  static const backgroundColor = Color(0xFFF5F5F5); // Nền xám cực nhẹ
  static const cardColor       = Colors.white;
  static const textPrimary     = Color(0xFF1C1C1E); // Chữ đen
  static const textSecondary   = Color(0xFF8E8E93); // Chữ xám mờ
  static const dividerColor    = Color(0xFFEEEEEE);

  // ── Material 3 Theme ─────────────────────────────────────────────────
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      primaryContainer: Color(0xFFFFDAD6),
      secondary: primaryLight,
      surface: cardColor,
      onPrimary: Colors.white,
      onSurface: textPrimary,
      error: Colors.redAccent,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
      headlineLarge: const TextStyle(
        color: textPrimary, fontWeight: FontWeight.bold, fontSize: 32, height: 1.2,
      ),
      headlineMedium: const TextStyle(
        color: textPrimary, fontWeight: FontWeight.bold, fontSize: 26,
      ),
      headlineSmall: const TextStyle(
        color: textPrimary, fontWeight: FontWeight.bold, fontSize: 20,
      ),
      titleLarge: const TextStyle(
        color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18,
      ),
      bodyLarge: const TextStyle(color: textSecondary, fontSize: 16, height: 1.5),
      bodyMedium: const TextStyle(color: textSecondary, fontSize: 14),
    ),

    // ── FilledButton ──────────────────────────────────────────────────
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    ),

    // ── ElevatedButton ────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    ),

    // ── OutlinedButton ────────────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: primaryColor, width: 1.5),
        foregroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
    ),

    // ── TextField ─────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: dividerColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
      hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    // ── AppBar ────────────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: dividerColor,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Outfit',
      ),
      centerTitle: true,
    ),

    // ── BottomNav / BottomAppBar ──────────────────────────────────────
    bottomAppBarTheme: const BottomAppBarThemeData(
      color: Colors.white,
      elevation: 8,
      surfaceTintColor: Colors.white,
    ),
    dividerTheme: const DividerThemeData(color: dividerColor, thickness: 1),
  );
}
