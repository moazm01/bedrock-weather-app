// Clean Architecture: Local Data Source
import '../../dto/weather_dto.dart';

// TODO: Implement with shared_preferences or hive for offline support
class WeatherCache {
  Future<void> cacheWeather(WeatherDto data) {
    throw UnimplementedError('TODO: Implement');
  }

  Future<WeatherDto?> getCachedWeather() {
    throw UnimplementedError('TODO: Implement');
  }

  Future<bool> isCacheValid() {
    throw UnimplementedError('TODO: Implement');
  }
}
