import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_performance/firebase_performance.dart';
import '../../../core/services/logger_service.dart';

class UsgsEarthquakeDataSource {
  Future<List<Map<String, dynamic>>> fetchEarthquakes(double lat, double lng) async {
    final trace = FirebasePerformance.instance.newTrace('fetch_earthquake_data');
    await trace.start();
    try {
      final minMag = 2.5;
      final uri = Uri.parse(
        'https://earthquake.usgs.gov/fdsnws/event/1/query'
        '?format=geojson&latitude=$lat&longitude=$lng'
        '&maxradius=5&minmagnitude=$minMag&orderby=time&limit=20',
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) throw Exception('USGS ${response.statusCode}');
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final features = (body['features'] as List).cast<Map<String, dynamic>>();
      await trace.stop();
      return features;
    } catch (e, stack) {
      await trace.stop();
      LoggerService.logError(e, stack, context: 'fetchEarthquakes');
      rethrow;
    }
  }
}
