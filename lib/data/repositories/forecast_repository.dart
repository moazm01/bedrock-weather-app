// Clean Architecture: Repository Implementation
import '../../domain/models/forecast_model.dart';
import '../../domain/models/weather_report_model.dart';
import '../../domain/enums/weather_enums.dart';
import '../../core/ml/weather_ml_pipeline.dart';

class ForecastRepository {
  final WeatherMLPipeline _pipeline = WeatherMLPipeline();

  Future<List<ForecastModel>> getMLForecast(double lat, double lng) async {
    final report = WeatherReport(
      id: 'input_report',
      purpose: WeatherReportPurpose.mlRetraining,
      temperature: 22.0,
      humidity: 70.0,
      pressure: 1012.0,
      windSpeed: 15.0,
      precipitation: 0.0,
      condition: 'partly_cloudy',
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
    );

    final features = await _pipeline.preprocessFeatures(report);
    final forecast = await _pipeline.runInference(features);
    
    return [forecast];
  }

  Future<void> submitTrainingData(Map<String, dynamic> weatherSnapshot) async {
    final report = WeatherReport(
      id: weatherSnapshot['id']?.toString() ?? '',
      purpose: WeatherReportPurpose.mlRetraining,
      temperature: (weatherSnapshot['temperature'] as num?)?.toDouble() ?? 20.0,
      humidity: (weatherSnapshot['humidity'] as num?)?.toDouble() ?? 50.0,
      pressure: (weatherSnapshot['pressure'] as num?)?.toDouble() ?? 1013.0,
      windSpeed: (weatherSnapshot['windSpeed'] as num?)?.toDouble() ?? 10.0,
      precipitation: (weatherSnapshot['precipitation'] as num?)?.toDouble() ?? 0.0,
      condition: weatherSnapshot['condition']?.toString() ?? 'clear',
      latitude: (weatherSnapshot['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (weatherSnapshot['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.now(),
    );
    await _pipeline.collectTrainingSnapshot(report);
  }
}
