// Clean Architecture: ML Repository
import '../../domain/models/weather_report_model.dart';
import '../../domain/models/forecast_model.dart';

class WeatherMLRepository {
  Future<void> storeTrainingData(WeatherReport report) {
    throw UnimplementedError('TODO: Implement');
  }

  Future<List<WeatherReport>> getTrainingHistory(DateTime from, DateTime to) {
    throw UnimplementedError('TODO: Implement');
  }

  // Uploads accumulated training data to cloud for centralized model retraining
  Future<void> uploadTrainingBatch(List<WeatherReport> batch) {
    throw UnimplementedError('TODO: Implement');
  }

  // Merges API forecast with ML prediction, weighted by model confidence score
  Future<ForecastModel> getHybridForecast(double lat, double lng) {
    throw UnimplementedError('TODO: Implement');
  }
}
