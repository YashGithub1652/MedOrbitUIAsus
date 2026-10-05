import 'package:flutter/material.dart';

class CrevaColors {
  // Primary brand
  static const Color primary = Color(0xFF2563EB);      // Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFFEFF6FF);
  static const Color accent = Color(0xFF7C3AED);        // Purple

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Urgency
  static const Color urgencyEmergency = Color(0xFFDC2626);
  static const Color urgencyHigh = Color(0xFFEF4444);
  static const Color urgencyMedium = Color(0xFFF59E0B);
  static const Color urgencyLow = Color(0xFF10B981);

  // Neutral
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Dark theme
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Legacy aliases
  static const Color glassBorder = Color(0xFF334155);
  static const Color darkCard = Color(0xFF1E293B);

  static Color? get bgWhite => null;

  static get textHint => null;
}

class CrevaTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: CrevaColors.primary,
          brightness: Brightness.light,
          primary: CrevaColors.primary,
          secondary: CrevaColors.accent,
          surface: CrevaColors.surface,
          error: CrevaColors.error,
        ),
        scaffoldBackgroundColor: CrevaColors.background,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: CrevaColors.surface,
          foregroundColor: CrevaColors.textPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: CrevaColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
          iconTheme: IconThemeData(color: CrevaColors.textPrimary),
        ),
        cardTheme: CardThemeData(
          color: CrevaColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: CrevaColors.border),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: CrevaColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: CrevaColors.primary,
            side: const BorderSide(color: CrevaColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: CrevaColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: CrevaColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: CrevaColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: CrevaColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: CrevaColors.error),
          ),
          labelStyle: const TextStyle(
            color: CrevaColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: const TextStyle(
            color: CrevaColors.textTertiary,
            fontSize: 15,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: CrevaColors.textPrimary,
            fontFamily: 'Inter',
          ),
          displayMedium: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: CrevaColors.textPrimary,
            fontFamily: 'Inter',
          ),
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: CrevaColors.textPrimary,
            fontFamily: 'Inter',
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: CrevaColors.textPrimary,
            fontFamily: 'Inter',
          ),
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: CrevaColors.textPrimary,
            fontFamily: 'Inter',
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CrevaColors.textPrimary,
            fontFamily: 'Inter',
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: CrevaColors.textPrimary,
            fontFamily: 'Inter',
          ),
          titleSmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CrevaColors.textPrimary,
            fontFamily: 'Inter',
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: CrevaColors.textPrimary,
            fontFamily: 'Inter',
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: CrevaColors.textSecondary,
            fontFamily: 'Inter',
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: CrevaColors.textTertiary,
            fontFamily: 'Inter',
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CrevaColors.textPrimary,
            fontFamily: 'Inter',
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: CrevaColors.textSecondary,
            letterSpacing: 0.5,
            fontFamily: 'Inter',
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: CrevaColors.surface,
          selectedItemColor: CrevaColors.primary,
          unselectedItemColor: CrevaColors.textTertiary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 11,
            fontFamily: 'Inter',
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: CrevaColors.border,
          thickness: 1,
          space: 1,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: CrevaColors.surfaceVariant,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: CrevaColors.textSecondary,
            fontFamily: 'Inter',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: CrevaColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: CrevaColors.primary,
          brightness: Brightness.dark,
          primary: CrevaColors.primary,
          secondary: CrevaColors.accent,
          surface: CrevaColors.darkSurface,
          error: CrevaColors.error,
        ),
        scaffoldBackgroundColor: CrevaColors.darkBackground,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: CrevaColors.darkSurface,
          foregroundColor: CrevaColors.darkTextPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: CrevaColors.darkTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        cardTheme: CardThemeData(
          color: CrevaColors.darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: CrevaColors.darkBorder),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: CrevaColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: CrevaColors.darkSurfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: CrevaColors.darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: CrevaColors.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: CrevaColors.primary, width: 1.5),
          ),
          labelStyle: const TextStyle(color: CrevaColors.darkTextSecondary),
          hintStyle: const TextStyle(color: CrevaColors.darkTextSecondary),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: CrevaColors.darkSurface,
          selectedItemColor: CrevaColors.primary,
          unselectedItemColor: CrevaColors.darkTextSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      );
}