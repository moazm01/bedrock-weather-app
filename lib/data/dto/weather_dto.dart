import '../../domain/models/weather_model.dart';

class WeatherDto {
  static WeatherModel parseCurrent(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    final code = current['weather_code'] as int? ?? 0;
    final mapped = mapWmoCode(code);

    return WeatherModel(
      temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (current['apparent_temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (current['relative_humidity_2m'] as num?)?.toDouble() ?? 0.0,
      pressure: (current['surface_pressure'] as num?)?.toDouble() ?? 1013.0,
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
      condition: mapped.$1,
      icon: mapped.$2,
      uvIndex: 0.0, // Open-Meteo requires additional endpoint for UV index
      visibility: (current['visibility'] as num?)?.toDouble() ?? 10000.0,
      precipitation: (current['precipitation'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.now(),
    );
  }

  static List<WeatherModel> parseHourly(Map<String, dynamic> json) {
    final hourly = json['hourly'] as Map<String, dynamic>;
    final times = hourly['time'] as List<dynamic>;
    final temps = hourly['temperature_2m'] as List<dynamic>;
    final codes = hourly['weather_code'] as List<dynamic>;
    final rainProbs = hourly['precipitation_probability'] as List<dynamic>?;

    final List<WeatherModel> list = [];
    final limit = times.length > 24 ? 24 : times.length; // Max 24 hours

    for (int i = 0; i < limit; i++) {
      final timeStr = times[i] as String;
      final code = codes[i] as int? ?? 0;
      final mapped = mapWmoCode(code);

      list.add(
        WeatherModel(
          temperature: (temps[i] as num?)?.toDouble() ?? 0.0,
          feelsLike: (temps[i] as num?)?.toDouble() ?? 0.0,
          humidity: 0.0,
          pressure: 1013.0,
          windSpeed: 0.0,
          condition: mapped.$1,
          icon: mapped.$2,
          uvIndex: 0.0,
          visibility: 10000.0,
          precipitation: rainProbs != null
              ? (rainProbs[i] as num?)?.toDouble() ?? 0.0
              : 0.0,
          timestamp: DateTime.tryParse(timeStr) ?? DateTime.now(),
        ),
      );
    }
    return list;
  }

  static List<WeatherModel> parseDaily(Map<String, dynamic> json) {
    final daily = json['daily'] as Map<String, dynamic>;
    final times = daily['time'] as List<dynamic>;
    final maxTemps = daily['temperature_2m_max'] as List<dynamic>;
    final minTemps = daily['temperature_2m_min'] as List<dynamic>;
    final codes = daily['weather_code'] as List<dynamic>;
    final rainProbs = daily['precipitation_probability_max'] as List<dynamic>?;

    final List<WeatherModel> list = [];
    final limit = times.length;

    for (int i = 0; i < limit; i++) {
      final timeStr = times[i] as String;
      final code = codes[i] as int? ?? 0;
      final mapped = mapWmoCode(code);
      final avgTemp =
          ((maxTemps[i] as num?)?.toDouble() ??
              0.0 + ((minTemps[i] as num?)?.toDouble() ?? 0.0)) /
          2;

      list.add(
        WeatherModel(
          temperature: avgTemp,
          // Hack min/max into feelsLike/pressure for easy representation in daily list
          feelsLike: (minTemps[i] as num?)?.toDouble() ?? 0.0, // Min Temp
          humidity: 0.0,
          pressure: (maxTemps[i] as num?)?.toDouble() ?? 0.0, // Max Temp
          windSpeed: 0.0,
          condition: mapped.$1,
          icon: mapped.$2,
          uvIndex: 0.0,
          visibility: 10000.0,
          precipitation: rainProbs != null
              ? (rainProbs[i] as num?)?.toDouble() ?? 0.0
              : 0.0, // Rain probability max
          timestamp: DateTime.tryParse(timeStr) ?? DateTime.now(),
        ),
      );
    }
    return list;
  }

  static (String condition, String icon) mapWmoCode(int code) {
    switch (code) {
      case 0:
        return ('Clear Sky', '☀️');
      case 1:
      case 2:
      case 3:
        return ('Partly Cloudy', '☁️');
      case 45:
      case 48:
        return ('Foggy', '🌫️');
      case 51:
      case 53:
      case 55:
        return ('Drizzle', '🌧️');
      case 61:
      case 63:
      case 65:
        return ('Rainy', '🌧️');
      case 80:
      case 81:
      case 82:
        return ('Rain Showers', '🌧️');
      case 95:
      case 96:
      case 99:
        return ('Thunderstorms', '⛈️');
      default:
        return ('Clear Sky', '☀️');
    }
  }
}
