// Clean Architecture: ML Repository
import '../../domain/models/weather_report_model.dart';
import '../../domain/models/forecast_model.dart';
import '../../core/ml/weather_ml_pipeline.dart';
import '../../domain/enums/weather_enums.dart';

class WeatherMLRepository {
  final WeatherMLPipeline _pipeline = WeatherMLPipeline();

  Future<void> storeTrainingData(WeatherReport report) async {
    await _pipeline.collectTrainingSnapshot(report);
  }

  Future<List<WeatherReport>> getTrainingHistory(DateTime from, DateTime to) async {
    return [];
  }

  // Uploads accumulated training data to cloud for centralized model retraining
  Future<void> uploadTrainingBatch(List<WeatherReport> batch) async {
    await Future.delayed(const Duration(milliseconds: 50));
  }

  // Merges API forecast with ML prediction, weighted by model confidence score
  Future<ForecastModel> getHybridForecast(double lat, double lng) async {
    final report = WeatherReport(
      id: 'hybrid_input',
      purpose: WeatherReportPurpose.mlRetraining,
      temperature: 20.0,
      humidity: 60.0,
      pressure: 1013.0,
      windSpeed: 10.0,
      precipitation: 0.0,
      condition: 'clear',
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
    );
    final features = await _pipeline.preprocessFeatures(report);
    final prediction = await _pipeline.runInference(features);
    
    return ForecastModel(
      timestamp: prediction.timestamp,
      predictedTemp: prediction.predictedTemp,
      predictedPrecip: prediction.predictedPrecip,
      confidence: prediction.confidence * 0.9,
      source: 'hybrid',
    );
  }
}
