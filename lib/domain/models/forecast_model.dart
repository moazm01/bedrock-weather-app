// Clean Architecture: Domain models
class ForecastModel {
  final DateTime timestamp;
  final double predictedTemp;
  final double predictedPrecip;
  final double confidence;
  final String source; // 'api', 'ml', 'hybrid'

  const ForecastModel({
    required this.timestamp,
    required this.predictedTemp,
    required this.predictedPrecip,
    required this.confidence,
    required this.source,
  });
}
