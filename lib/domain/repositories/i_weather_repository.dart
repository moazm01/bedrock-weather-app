// Clean Architecture: Domain repository interface
import '../models/weather_model.dart';

abstract class IWeatherRepository {
  Future<WeatherModel> getCurrentWeather(double lat, double lng);
  Future<List<WeatherModel>> getHourlyForecast(double lat, double lng);
  Future<List<WeatherModel>> getDailyForecast(double lat, double lng, int days);
  bool get isUsingServerCache;
}
