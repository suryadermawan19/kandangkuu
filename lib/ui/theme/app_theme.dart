import 'package:flutter/material.dart';

/// Clean Universal Light Theme for PoultryVision (Kandangku)
/// Optimized for readability (elderly + young farmers) with professional aesthetics
class AppTheme {
  // Traffic Light Status Colors (Unchanged - Used as Accents)
  static const Color statusGreen = Color(0xFF2E7D32); // Forest Green - Optimal
  static const Color statusAmber = Color(0xFFFF8F00); // Golden Amber - Warning
  static const Color statusRed = Color(0xFFD32F2F); // Alert Red - Critical

  // Light Mode Background Colors
  static const Color lightBackground = Color(0xFFF5F5F5); // Very light grey
  static const Color cardBackground = Color(0xFFFFFFFF); // Pure white
  static const Color surfaceBackground = Color(0xFFFAFAFA); // Soft white

  // Light Mode Text Colors (High Contrast)
  static const Color textPrimary = Color(0xFF333333); // Dark charcoal
  static const Color textSecondary = Color(0xFF666666); // Medium grey
  static const Color textDisabled = Color(0xFFBDBDBD); // Light grey

  // Mode Indicators (Unchanged - Used as Accents)
  static const Color autoModeBlue = Color(0xFF03A9F4);
  static const Color manualModeOrange = Color(0xFFFF6F00);

  // Typography Styles - Standard & Clear
  static const TextStyle sensorValueStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800, // ExtraBold
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle sensorLabelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600, // SemiBold
    color: textSecondary,
    letterSpacing: 0.3,
  );

  static const TextStyle sensorUnitStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
    color: textSecondary,
  );

  static const TextStyle statusTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700, // Bold
    color: textPrimary,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const TextStyle bodyTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  // Material 3 Light Theme
  static ThemeData get theme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: lightBackground,
      primaryColor: statusGreen,
      colorScheme: const ColorScheme.light(
        primary: statusGreen,
        secondary: statusAmber,
        error: statusRed,
        surface: cardBackground,
        surfaceContainerHighest: surfaceBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return statusGreen;
          }
          if (states.contains(WidgetState.disabled)) {
            return textDisabled;
          }
          return textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return statusGreen.withValues(alpha: 0.5);
          }
          if (states.contains(WidgetState.disabled)) {
            return textDisabled.withValues(alpha: 0.3);
          }
          return textSecondary.withValues(alpha: 0.3);
        }),
      ),
      textTheme: const TextTheme(
        displayLarge: sensorValueStyle,
        titleLarge: cardTitleStyle,
        bodyLarge: bodyTextStyle,
        labelLarge: sensorLabelStyle,
      ),
    );
  }

  // Helper methods to get status color based on sensor thresholds
  static Color getTemperatureStatusColor(double temperature) {
    if (temperature > 30) return statusRed;
    if (temperature > 28) return statusAmber;
    return statusGreen;
  }

  static Color getHumidityStatusColor(double humidity) {
    if (humidity > 75 || humidity < 40) return statusRed;
    if (humidity > 70 || humidity < 45) return statusAmber;
    return statusGreen;
  }

  static Color getAmmoniaStatusColor(double ammonia) {
    if (ammonia > 20) return statusRed;
    if (ammonia > 15) return statusAmber;
    return statusGreen;
  }

  static Color getFeedWeightStatusColor(double feedWeight) {
    if (feedWeight < 10) return statusRed;
    if (feedWeight < 20) return statusAmber;
    return statusGreen;
  }

  static Color getWaterLevelStatusColor(String waterLevel) {
    if (waterLevel.toLowerCase() == 'empty' ||
        waterLevel.toLowerCase() == 'low' ||
        waterLevel.toLowerCase() == 'kosong') {
      return statusRed;
    }
    if (waterLevel.toLowerCase() == 'medium' ||
        waterLevel.toLowerCase() == 'sedang') {
      return statusAmber;
    }
    return statusGreen;
  }

  static Color getVisionScoreStatusColor(int visionScore) {
    if (visionScore < 40 || visionScore >= 70) {
      return statusRed; // Critical both ends
    }
    return statusGreen; // Comfortable range 40-69
  }
}
