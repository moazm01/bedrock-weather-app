import '../../domain/repositories/i_weather_repository.dart';
import '../../domain/models/weather_model.dart';
import '../datasources/remote/open_meteo_datasource.dart';
import '../dto/weather_dto.dart';

import 'package:firebase_performance/firebase_performance.dart';

class WeatherRepository implements IWeatherRepository {
  final OpenMeteoWeatherDataSource _weatherDataSource;
  final FirebasePerformance? _performance;

  // Local caching variables to prevent multiple network queries on the same frame
  Map<String, dynamic>? _cachedJson;
  DateTime? _cacheTime;
  double? _cachedLat;
  double? _cachedLng;

  WeatherRepository(
    this._weatherDataSource, {
    this._performance,
  });

  @override
  bool get isUsingServerCache => _weatherDataSource.lastRequestUsedServerCache;

  Future<Map<String, dynamic>> _getOrFetchWeather(
    double lat,
    double lng,
  ) async {
    final now = DateTime.now();
    if (_cachedJson != null &&
        _cacheTime != null &&
        _cachedLat != null &&
        _cachedLng != null &&
        now.difference(_cacheTime!).inSeconds < 10 &&
        (lat - _cachedLat!).abs() < 0.01 &&
        (lng - _cachedLng!).abs() < 0.01) {
      return _cachedJson!;
    }

    final performance = _performance ?? FirebasePerformance.instance;
    final trace = performance.newTrace('fetch_weather_data');
    await trace.start();
    try {
      final json = await _weatherDataSource.fetchWeatherData(lat, lng);
      _cachedJson = json;
      _cacheTime = now;
      _cachedLat = lat;
      _cachedLng = lng;
      await trace.stop();
      return json;
    } catch (_) {
      await trace.stop();
      rethrow;
    }
  }

  @override
  Future<WeatherModel> getCurrentWeather(double lat, double lng) async {
    final json = await _getOrFetchWeather(lat, lng);
    return WeatherDto.parseCurrent(json);
  }

  @override
  Future<List<WeatherModel>> getHourlyForecast(double lat, double lng) async {
    final json = await _getOrFetchWeather(lat, lng);
    return WeatherDto.parseHourly(json);
  }

  @override
  Future<List<WeatherModel>> getDailyForecast(
    double lat,
    double lng,
    int days,
  ) async {
    final json = await _getOrFetchWeather(lat, lng);
    return WeatherDto.parseDaily(json);
  }
}
