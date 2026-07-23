// Clean Architecture: Local Data Source
import '../../dto/weather_dto.dart';

// TODO: Implement with shared_preferences or hive for offline support
class WeatherCache {
  Future<void> cacheWeather(WeatherDto data) async {}
  Future<WeatherDto?> getCachedWeather() async => null;
  Future<bool> isCacheValid() async => false;
}
