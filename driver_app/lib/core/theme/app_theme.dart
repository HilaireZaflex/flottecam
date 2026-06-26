import 'package:flutter/material.dart';

class AppTheme {
  static const primary    = Color(0xFF1B4FD8);
  static const success    = Color(0xFF16A34A);
  static const warning    = Color(0xFFEA580C);
  static const error      = Color(0xFFDC2626);
  static const background = Color(0xFFF8FAFC);
  static const textPrimary   = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: primary,
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
