import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_performance/firebase_performance.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/services/logger_service.dart';

class UsgsEarthquakeDataSource {
  bool lastRequestUsedServerCache = true;

  Future<List<Map<String, dynamic>>> fetchEarthquakes(double lat, double lng) async {
    final trace = FirebasePerformance.instance.newTrace('fetch_earthquake_data');
    await trace.start();
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('getEarthquakeData');
      final result = await callable.call(<String, dynamic>{
        'lat': lat,
        'lng': lng,
      });
      lastRequestUsedServerCache = true;
      final listData = result.data as List;
      final List<Map<String, dynamic>> features = listData.map((e) => _castMap(e as Map)).toList();
      await trace.stop();
      return features;
    } catch (_) {
      lastRequestUsedServerCache = false;
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
        LoggerService.logError(e, stack, context: 'fetchEarthquakesFallback');
        rethrow;
      }
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
