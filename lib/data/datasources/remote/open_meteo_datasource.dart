import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenMeteoWeatherDataSource {
  Future<Map<String, dynamic>> fetchWeatherData(double lat, double lng) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lng'
      '&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,surface_pressure,wind_speed_10m,weather_code,visibility'
      '&hourly=temperature_2m,weather_code,precipitation_probability'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max'
      '&timezone=auto&forecast_days=7',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch weather: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
