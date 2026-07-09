import 'package:flutter/material.dart';
import '../../domain/models/weather_model.dart';
import '../../data/repositories/weather_repository.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherRepository _weatherRepository;

  WeatherModel? _currentWeather;
  List<WeatherModel> _hourlyForecast = [];
  List<WeatherModel> _dailyForecast = [];
  bool _isLoading = false;
  String? _errorMessage;

  WeatherProvider(this._weatherRepository);

  WeatherModel? get currentWeather => _currentWeather;
  List<WeatherModel> get hourlyForecast => _hourlyForecast;
  List<WeatherModel> get dailyForecast => _dailyForecast;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchWeather(double lat, double lng) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Execute in parallel to speed up loading
      final futures = await Future.wait([
        _weatherRepository.getCurrentWeather(lat, lng),
        _weatherRepository.getHourlyForecast(lat, lng),
        _weatherRepository.getDailyForecast(lat, lng, 7),
      ]);

      _currentWeather = futures[0] as WeatherModel;
      _hourlyForecast = futures[1] as List<WeatherModel>;
      _dailyForecast = futures[2] as List<WeatherModel>;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
