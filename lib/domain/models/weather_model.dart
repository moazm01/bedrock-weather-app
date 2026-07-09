// Clean Architecture: Domain models
class WeatherModel {
  final double temperature;
  final double feelsLike;
  final double humidity;
  final double pressure;
  final double windSpeed;
  final String condition;
  final String icon;
  final double uvIndex;
  final double visibility;
  final double precipitation;
  final DateTime timestamp;

  const WeatherModel({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.condition,
    required this.icon,
    required this.uvIndex,
    required this.visibility,
    required this.precipitation,
    required this.timestamp,
  });
}
