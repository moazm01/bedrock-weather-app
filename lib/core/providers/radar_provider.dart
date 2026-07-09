import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RadarProvider extends ChangeNotifier {
  final http.Client _client = http.Client();

  String? _latestTimestamp;
  bool _isRadarVisible = false;
  bool _isLoading = false;

  String? get latestTimestamp => _latestTimestamp;
  bool get isRadarVisible => _isRadarVisible;
  bool get isLoading => _isLoading;

  Future<void> fetchLatestRadar() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _client.get(
        Uri.parse('https://api.rainviewer.com/public/weather-maps.json'),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final radarTimes = decoded['radar']?['past'] as List<dynamic>?;
        if (radarTimes != null && radarTimes.isNotEmpty) {
          // The last item in past is the latest radar snapshot
          final latestItem = radarTimes.last as Map<String, dynamic>;
          _latestTimestamp = latestItem['time']?.toString();
        }
      }
    } catch (_) {
      // Fallback to a relative timestamp approximation if API fails
      _latestTimestamp =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000 ~/ 600 * 600)
              .toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleRadar() {
    _isRadarVisible = !_isRadarVisible;
    if (_isRadarVisible && _latestTimestamp == null) {
      fetchLatestRadar();
    } else {
      notifyListeners();
    }
  }
}
