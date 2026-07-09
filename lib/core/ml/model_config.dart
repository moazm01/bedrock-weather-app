// Clean Architecture: ML model configuration
class ModelConfig {
  // TODO: Update with actual model paths and feature configs after training

  static const String weatherForecastModel =
      'assets/models/weather_forecast.tflite';
  static const String hazardPredictionModel =
      'assets/models/hazard_prediction.tflite';

  static const int forecastHorizonHours = 48;
  static const List<String> inputFeatures = [
    'temperature',
    'humidity',
    'pressure',
    'wind_speed',
    'precipitation',
    'cloud_cover',
  ];
}
