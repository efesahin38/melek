import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // === COLORS ===
  static const Color bgDark = Color(0xFF0A0A1A);
  static const Color bgCard = Color(0xFF12122A);
  static const Color bgCardElevated = Color(0xFF1A1A38);
  static const Color bgCardLight = Color(0xFF1E1E40);

  static const Color goldPrimary = Color(0xFFC9A227);
  static const Color goldLight = Color(0xFFE8C547);
  static const Color goldDark = Color(0xFF8B6914);
  static const Color goldVeryLight = Color(0xFFFFF3CD);
  static const Color goldGlow = Color(0x33C9A227);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8888AA);
  static const Color textGold = Color(0xFFE8C547);
  static const Color textMuted = Color(0xFF55557A);

  static const Color success = Color(0xFF44DD88);
  static const Color successBg = Color(0x1A44DD88);
  static const Color error = Color(0xFFFF4466);
  static const Color errorBg = Color(0x1AFF4466);
  static const Color warning = Color(0xFFFFAA22);
  static const Color warningBg = Color(0x1AFFAA22);
  static const Color info = Color(0xFF4488FF);
  static const Color infoBg = Color(0x1A4488FF);

  static const Color divider = Color(0xFF1E1E3A);
  static const Color border = Color(0xFF2A2A4A);
  static const Color borderGold = Color(0x55C9A227);

  // === GRADIENTS ===
  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldDark, goldPrimary, goldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradientSubtle = LinearGradient(
    colors: [Color(0xFF1A1400), Color(0xFF2A2000), Color(0xFF1A1400)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0A0A1A), Color(0xFF0F0F24), Color(0xFF0A0A1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // === SHADOWS ===
  static List<BoxShadow> goldShadow = [
    BoxShadow(
      color: goldPrimary.withOpacity(0.3),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // === THEME ===
  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    colorScheme: const ColorScheme.dark(
      primary: goldPrimary,
      secondary: goldLight,
      surface: bgCard,
      error: error,
      onPrimary: bgDark,
      onSecondary: bgDark,
      onSurface: textPrimary,
    ),
    textTheme: GoogleFonts.outfitTextTheme(
      const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        displaySmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
        bodySmall: TextStyle(color: textMuted),
        labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(color: textMuted),
      ),
    ),
    cardTheme: CardThemeData(
      color: bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderGold, width: 1),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bgDark,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: goldPrimary),
      titleTextStyle: GoogleFonts.outfit(
        color: goldLight,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: bgCard,
      selectedItemColor: goldPrimary,
      unselectedItemColor: textMuted,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgCardElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: goldPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error),
      ),
      hintStyle: const TextStyle(color: textMuted),
      labelStyle: const TextStyle(color: textSecondary),
      prefixIconColor: goldPrimary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: goldPrimary,
        foregroundColor: bgDark,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: goldPrimary,
        textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    dividerTheme: const DividerThemeData(color: divider, thickness: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: borderGold),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: bgCardElevated,
      contentTextStyle: GoogleFonts.outfit(color: textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: goldPrimary,
      foregroundColor: bgDark,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: bgCardElevated,
      selectedColor: goldGlow,
      labelStyle: const TextStyle(color: textPrimary),
      side: const BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
