import 'package:flutter/material.dart';
import 'colors.dart';
import 'text_styles.dart';

class RimaTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: RimaColors.background,

      colorScheme: ColorScheme.fromSeed(
        seedColor: RimaColors.primary,
        primary: RimaColors.primary,
      ),

     appBarTheme: const AppBarTheme(
  backgroundColor: Colors.transparent,
  foregroundColor: RimaColors.primary,
  iconTheme: IconThemeData(
    color: RimaColors.primary,
  ),
  actionsIconTheme: IconThemeData(
    color: RimaColors.primary,
  ),
  elevation: 0,
),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RimaColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      textTheme: const TextTheme(
        headlineLarge: RimaTextStyles.heading,
        headlineMedium: RimaTextStyles.title,
        bodyLarge: RimaTextStyles.body,
        bodyMedium: RimaTextStyles.subtitle,
      ),
    );
  }
}