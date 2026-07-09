import 'package:flutter/material.dart';

// BedrockTheme defines the application's global visual styling configurations.
// Official Reference: https://docs.flutter.dev/cookbook/design/themes
class BedrockTheme {
  // Pure AMOLED Colors
  static const Color scaffoldDark = Color(0xFF000000); // True Black
  static const Color surfaceDark = Color(
    0xFF16161A,
  ); // Apple SystemGray6 (Subtle off-black)
  static const Color cardDark = Color(0xFF0D0D11); // Grouped card surface
  static const Color borderSubtle = Color(0xFF2C2C2E); // Subdued card border
  static const Color labelPrimaryDark = Color(0xFFFFFFFF);
  static const Color labelSecondaryDark = Color(0xFF8E8E93); // Apple SystemGray

  // Semantic Colors
  static const Color hazardSafeDark = Color(0xFF30D158); // Apple Green
  static const Color hazardCautionDark = Color(0xFFBF5AF2); // Apple Purple
  static const Color hazardWarningDark = Color(0xFFFF9F0A); // Apple Orange
  static const Color hazardCriticalDark = Color(0xFFFF453A); // Apple Red

  // True Apple Blue Accent
  static const Color accentBlueDark = Color(0xFF0A84FF);

  // Return configurations representing ThemeData for Dark Mode.
  // Reference: https://api.flutter.dev/flutter/material/ThemeData-class.html
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: accentBlueDark,
      scaffoldBackgroundColor: scaffoldDark,

      colorScheme: const ColorScheme.dark(
        primary: accentBlueDark,
        secondary: surfaceDark,
        surface: scaffoldDark,
        error: hazardCriticalDark,
        onPrimary: Colors.white,
        onSecondary: labelPrimaryDark,
        onSurface: labelPrimaryDark,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldDark,
        foregroundColor: labelPrimaryDark,
        elevation: 0,
        centerTitle: true,
      ),

      // Input Field Focused/Enabled Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C1C1E),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(color: labelSecondaryDark, fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentBlueDark, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: hazardCriticalDark, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: hazardCriticalDark, width: 1.2),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: scaffoldDark,
        selectedItemColor: accentBlueDark,
        unselectedItemColor: Color(0xFF48484A),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      // Dialog Theme to fix white boxes in dark theme
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderSubtle, width: 1.0),
        ),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: labelPrimaryDark,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 15,
          color: labelPrimaryDark,
        ),
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1C1C1E),
        contentTextStyle: const TextStyle(color: labelPrimaryDark),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderSubtle, width: 1.0),
        ),
      ),

      // Global smooth transitions between screens (Named Routes)
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        },
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 34,
          color: labelPrimaryDark,
          letterSpacing: 0.37,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 22,
          color: labelPrimaryDark,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 17,
          color: labelPrimaryDark,
          letterSpacing: -0.41,
        ),
        bodyLarge: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 17,
          color: labelPrimaryDark,
          letterSpacing: -0.41,
        ),
        bodyMedium: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 15,
          color: labelPrimaryDark,
          letterSpacing: -0.24,
        ),
        labelSmall: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
          color: labelSecondaryDark,
        ),
      ),
    );
  }
}
