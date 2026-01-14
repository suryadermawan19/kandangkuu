import 'package:flutter/material.dart';

/// Industrial Green Dark Theme for Kandangku IoT Dashboard
/// Bahasa Indonesia Version
class DarkTheme {
  // Core Palette - Industrial Green
  static const Color deepForestBlack = Color(0xFF112214);
  static const Color darkGreenGlass = Color(0xFF24472a);
  static const Color neonGreen = Color(0xFF17cf36);
  static const Color paleGreen = Color(0xFF93c89c);

  // Semantic Colors
  static const Color backgroundPrimary = deepForestBlack;
  static const Color cardBackground = darkGreenGlass;
  static const Color accentPrimary = neonGreen;
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = paleGreen;
  static const Color textDisabled = Color(0xFF5a7a5f);

  // Status Colors
  static const Color statusSafe = neonGreen;
  static const Color statusWarning = Color(0xFFFF9500);
  static const Color statusDanger = Color(0xFFFF3B30);

  // Border Colors
  static Color get cardBorder => neonGreen.withValues(alpha: 0.2);
  static Color get cardBorderActive => neonGreen.withValues(alpha: 0.5);

  // Navigation Colors
  static const Color navBackground = deepForestBlack;
  static const Color navActive = neonGreen;
  static const Color navInactive = paleGreen;

  // Card Decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: cardBorder, width: 1),
  );

  static BoxDecoration get cardDecorationActive => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: cardBorderActive, width: 1.5),
    boxShadow: [
      BoxShadow(
        color: neonGreen.withValues(alpha: 0.15),
        blurRadius: 12,
        spreadRadius: 0,
      ),
    ],
  );

  // Typography
  static const TextStyle headerTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    fontFamily: 'Inter',
    letterSpacing: -0.3,
  );

  static const TextStyle headerSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: paleGreen,
    fontFamily: 'Inter',
  );

  static const TextStyle sensorValue = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    fontFamily: 'Inter',
    letterSpacing: -0.5,
    height: 1.1,
  );

  static const TextStyle sensorLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: paleGreen,
    fontFamily: 'Inter',
  );

  static const TextStyle badgeText = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: deepForestBlack,
    fontFamily: 'Inter',
    letterSpacing: 0.5,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: 'Inter',
  );

  static const TextStyle controlTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: 'Inter',
  );

  static const TextStyle controlSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: paleGreen,
    fontFamily: 'Inter',
  );

  static const TextStyle navLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontFamily: 'Inter',
  );

  // Material Theme
  static ThemeData get theme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: backgroundPrimary,
      primaryColor: accentPrimary,
      colorScheme: const ColorScheme.dark(
        primary: neonGreen,
        secondary: paleGreen,
        surface: cardBackground,
        error: statusDanger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: deepForestBlack,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: headerTitle,
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cardBorder, width: 1),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return neonGreen;
          return textDisabled;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return neonGreen.withValues(alpha: 0.4);
          }
          return textDisabled.withValues(alpha: 0.3);
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: navBackground,
        selectedItemColor: navActive,
        unselectedItemColor: navInactive,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: navLabel,
        unselectedLabelStyle: navLabel,
      ),
    );
  }

  // Sensor Status Helpers
  static Color getTemperatureStatus(double temp) {
    if (temp > 32 || temp < 22) return statusDanger;
    if (temp > 30 || temp < 24) return statusWarning;
    return statusSafe;
  }

  static Color getAmmoniaStatus(double ppm) {
    if (ppm > 25) return statusDanger;
    if (ppm > 15) return statusWarning;
    return statusSafe;
  }

  static String getTemperatureStatusText(double temp) {
    if (temp > 32 || temp < 22) return 'Bahaya';
    if (temp > 30 || temp < 24) return 'Awas';
    return 'Aman';
  }

  static String getAmmoniaStatusText(double ppm) {
    if (ppm > 25) return 'Bahaya';
    if (ppm > 15) return 'Awas';
    return 'Aman';
  }

  static String getVisionStatusText(int score) {
    if (score >= 80) return 'Nyaman';
    if (score >= 60) return 'Normal';
    if (score >= 40) return 'Perlu Perhatian';
    return 'Kritis';
  }

  // Feed Weight Helpers
  static Color getFeedWeightStatus(double kg) {
    if (kg < 1.0) return statusDanger;
    if (kg < 2.0) return statusWarning;
    return statusSafe;
  }

  static String getFeedWeightStatusText(double kg) {
    if (kg < 1.0) return 'Habis!';
    if (kg < 2.0) return 'Rendah';
    return 'Cukup';
  }

  // Water Level Helpers
  static Color getWaterLevelStatus(String level) {
    final lower = level.toLowerCase();
    if (lower == 'empty' || lower == 'habis' || lower == 'kosong') {
      return statusDanger;
    }
    if (lower == 'low' || lower == 'rendah') {
      return statusWarning;
    }
    return statusSafe;
  }

  static String getWaterLevelStatusText(String level) {
    final lower = level.toLowerCase();
    if (lower == 'empty' || lower == 'habis' || lower == 'kosong') {
      return 'Habis!';
    }
    if (lower == 'low' || lower == 'rendah') {
      return 'Rendah';
    }
    if (lower == 'full' || lower == 'penuh') {
      return 'Penuh';
    }
    return 'Normal';
  }

  static String getWaterLevelDisplayText(String level) {
    final lower = level.toLowerCase();
    if (lower == 'empty' || lower == 'habis' || lower == 'kosong') {
      return 'Kosong';
    }
    if (lower == 'low' || lower == 'rendah') {
      return 'Rendah';
    }
    if (lower == 'full' || lower == 'penuh') {
      return 'Penuh';
    }
    return 'Normal';
  }
}
