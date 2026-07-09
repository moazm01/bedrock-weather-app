import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class UsgsEarthquakeDataSource {
  final http.Client _client = http.Client();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchEarthquakes(
    double lat,
    double lng,
  ) async {
    final now = DateTime.now();
    // Cache per hour for the given location (rounded to 1 decimal place ~11km precision)
    final cacheId =
        'eq_${lat.toStringAsFixed(1)}_${lng.toStringAsFixed(1)}_${now.year}-${now.month}-${now.day}-${now.hour}';
    final cacheRef = _firestore.collection('earthquake_snapshots').doc(cacheId);

    try {
      final doc = await cacheRef.get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final age = now.difference((data['fetchedAt'] as Timestamp).toDate());
        if (age.inMinutes < 60) {
          final List<dynamic> list =
              jsonDecode(data['featuresJson'] as String) as List<dynamic>;
          return list.map((e) => e as Map<String, dynamic>).toList();
        }
      }
    } catch (_) {
      // Ignore cache reading errors, fallback to API
    }

    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final starttime =
        '${thirtyDaysAgo.year}-${thirtyDaysAgo.month.toString().padLeft(2, '0')}-${thirtyDaysAgo.day.toString().padLeft(2, '0')}';

    final url =
        'https://earthquake.usgs.gov/fdsnws/event/1/query'
        '?format=geojson'
        '&starttime=$starttime'
        '&minmagnitude=2.5'
        '&latitude=$lat'
        '&longitude=$lng'
        '&maxradiuskm=500';

    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch earthquakes from USGS (code: ${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final features = decoded['features'] as List<dynamic>? ?? [];
    final List<Map<String, dynamic>> parsedFeatures = features
        .map((e) => e as Map<String, dynamic>)
        .toList();

    try {
      // Save to cache
      await cacheRef.set({
        'fetchedAt': FieldValue.serverTimestamp(),
        'latitude': lat,
        'longitude': lng,
        'featuresJson': jsonEncode(parsedFeatures),
      });
    } catch (_) {
      // Ignore cache writing errors
    }

    return parsedFeatures;
  }
}
