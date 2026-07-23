// Clean Architecture: Dual-purpose weather reports for hazard triggering and ML training
import '../enums/weather_enums.dart';

class WeatherReport {
  final String id;
  final WeatherReportPurpose purpose;
  final double temperature;
  final double humidity;
  final double pressure;
  final double windSpeed;
  final double precipitation;
  final String condition;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final Map<String, dynamic>?
  rawApiPayload; // original API response for ML training

  const WeatherReport({
    required this.id,
    required this.purpose,
    required this.temperature,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.precipitation,
    required this.condition,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.rawApiPayload,
  });
}
