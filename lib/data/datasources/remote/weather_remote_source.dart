// Clean Architecture: Remote Data Source
import '../../dto/weather_dto.dart';

class WeatherRemoteSource {
  // TODO: Implement weather API calls

  Future<WeatherDto> fetchCurrentWeather(double lat, double lng) {
    throw UnimplementedError('TODO: Implement');
  }

  Future<List<WeatherDto>> fetchHourlyForecast(double lat, double lng) {
    throw UnimplementedError('TODO: Implement');
  }

  Future<List<WeatherDto>> fetchDailyForecast(
    double lat,
    double lng,
    int days,
  ) {
    throw UnimplementedError('TODO: Implement');
  }
}
