// Clean Architecture: Weather Enums
import 'package:flutter/material.dart';
import '../../core/theme/bedrock_theme.dart';

enum WeatherReportPurpose { hazardDetection, mlTraining, general }

enum WeatherSeverity { normal, advisory, watch, warning, emergency }

enum WeatherDataSource { openWeatherMap, weatherApi, aemet, custom }

extension WeatherSeverityX on WeatherSeverity {
  String get displayName {
    switch (this) {
      case WeatherSeverity.normal:
        return 'Normal';
      case WeatherSeverity.advisory:
        return 'Advisory';
      case WeatherSeverity.watch:
        return 'Watch';
      case WeatherSeverity.warning:
        return 'Warning';
      case WeatherSeverity.emergency:
        return 'Emergency';
    }
  }

  Color get color {
    switch (this) {
      case WeatherSeverity.normal:
        return BedrockTheme.hazardSafeDark;
      case WeatherSeverity.advisory:
        return BedrockTheme.hazardWarningDark;
      case WeatherSeverity.watch:
        return Colors.orangeAccent;
      case WeatherSeverity.warning:
        return BedrockTheme.hazardCriticalDark;
      case WeatherSeverity.emergency:
        return Colors.red;
    }
  }
}
