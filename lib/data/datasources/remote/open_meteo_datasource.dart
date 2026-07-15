import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_functions/cloud_functions.dart';

class OpenMeteoWeatherDataSource {
  bool lastRequestUsedServerCache = true;

  Future<Map<String, dynamic>> fetchWeatherData(double lat, double lng) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('getWeatherData');
      final result = await callable.call(<String, dynamic>{
        'lat': lat,
        'lng': lng,
      });
      lastRequestUsedServerCache = true;
      // Convert nested maps safely
      final Map<dynamic, dynamic> dataMap = result.data as Map<dynamic, dynamic>;
      return _castMap(dataMap);
    } catch (_) {
      lastRequestUsedServerCache = false;
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

  Map<String, dynamic> _castMap(Map<dynamic, dynamic> map) {
    return map.map((key, value) {
      final String stringKey = key.toString();
      if (value is Map) {
        return MapEntry(stringKey, _castMap(value));
      } else if (value is List) {
        return MapEntry(stringKey, value.map((item) {
          if (item is Map) {
            return _castMap(item);
          }
          return item;
        }).toList());
      }
      return MapEntry(stringKey, value);
    });
  }
}
