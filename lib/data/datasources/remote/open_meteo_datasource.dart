import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class OpenMeteoWeatherDataSource {
  final http.Client _client = http.Client();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> fetchWeatherData(double lat, double lng) async {
    // Generate cache key based on coordinates (rounded to 2 decimal places ~1.1km precision)
    // and the current hour to avoid unnecessary API requests.
    final now = DateTime.now();
    final cacheId =
        'weather_${lat.toStringAsFixed(2)}_${lng.toStringAsFixed(2)}_${now.year}-${now.month}-${now.day}-${now.hour}';
    final cacheRef = _firestore.collection('weather_snapshots').doc(cacheId);

    try {
      final doc = await cacheRef.get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final age = now.difference((data['fetchedAt'] as Timestamp).toDate());
        // If cached data is less than 30 minutes old, return it
        if (age.inMinutes < 30) {
          return jsonDecode(data['rawJson'] as String) as Map<String, dynamic>;
        }
      }
    } catch (_) {
      // If Firestore fails, fall back to direct HTTP fetch
    }

    // Direct HTTP fetch from Open-Meteo API
    final url =
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lng'
        '&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,surface_pressure,wind_speed_10m,weather_code,visibility'
        '&hourly=temperature_2m,weather_code,precipitation_probability'
        '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max'
        '&timezone=Asia%2FKarachi';

    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch weather from Open-Meteo API (code: ${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    try {
      // Save snapshot to Firestore cache
      await cacheRef.set({
        'fetchedAt': FieldValue.serverTimestamp(),
        'latitude': lat,
        'longitude': lng,
        'rawJson': response.body,
      });
    } catch (_) {
      // Ignore cache write errors
    }

    return decoded;
  }
}
