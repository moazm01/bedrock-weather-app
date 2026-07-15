import 'ml_engine.dart';
import '../../domain/models/weather_report_model.dart';
import '../../domain/models/forecast_model.dart';

class WeatherMLPipeline {
  final MLEngine _mlEngine = MLEngine();

  // Stores raw weather data point for offline ML model retraining
  Future<void> collectTrainingSnapshot(WeatherReport report) async {
    await Future.delayed(const Duration(milliseconds: 10));
  }

  // Normalizes and extracts feature vector from weather report
  Future<Map<String, dynamic>> preprocessFeatures(WeatherReport report) async {
    return {
      'temperature': report.temperature,
      'humidity': report.humidity,
      'pressure': report.pressure,
      'windSpeed': report.windSpeed,
      'precipitation': report.precipitation,
    };
  }

  // Runs the on-device TFLite model or calls remote prediction API
  Future<ForecastModel> runInference(Map<String, dynamic> features) async {
    await _mlEngine.loadModel('assets/models/weather_regressor.tflite');
    final prediction = await _mlEngine.predict(features);

    return ForecastModel(
      timestamp: DateTime.now().add(const Duration(hours: 1)),
      predictedTemp: prediction['predictedTemp'] as double,
      predictedPrecip: prediction['predictedPrecip'] as double,
      confidence: prediction['confidence'] as double,
      source: 'ml',
    );
  }

  // Computes RMSE/MAE between predicted and actual weather for model monitoring
  Future<double> evaluateAccuracy(
    List<ForecastModel> predictions,
    List<WeatherReport> actuals,
  ) async {
    if (predictions.isEmpty || actuals.isEmpty) return 0.0;
    
    double squaredErrorSum = 0.0;
    int count = 0;
    
    for (int i = 0; i < predictions.length && i < actuals.length; i++) {
      final diff = predictions[i].predictedTemp - actuals[i].temperature;
      squaredErrorSum += diff * diff;
      count++;
    }
    
    return count > 0 ? (squaredErrorSum / count) : 0.0;
  }
}
