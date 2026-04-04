import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Theme mang phong cách Shopee Food (Sáng, Trẻ trung, Màu cam chủ đạo)
  static const primaryColor = Color(0xFFEE4D2D); // Shopee Orange
  static const secondaryColor = Color(0xFFFF6E40); // Lighter Orange
  static const accentColor = Color(0xFF00B14F); // Fresh Green (Grab)
  static const backgroundColor = Color(0xFFF8F9FA); // Rất sáng, gần như trắng
  static const cardColor = Colors.white;
  static const textPrimary = Color(0xFF212121); // Chữ màu tối
  static const textSecondary = Color(0xFF757575); // Chữ xám mờ

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: cardColor,
      onSurface: textPrimary,
      error: Colors.redAccent,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
      headlineMedium: const TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 28,
      ),
      bodyLarge: const TextStyle(
        color: textSecondary,
        fontSize: 16,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none, // Bỏ viền default
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEEEEEE), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: textSecondary),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
    ),
  );
}
