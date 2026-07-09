// Clean Architecture: Data Transfer Objects
class ForecastDto {
  final DateTime timestamp;
  final double predictedTemp;
  final double predictedPrecipitation;
  final double confidence;
  final String source;

  ForecastDto({
    required this.timestamp,
    required this.predictedTemp,
    required this.predictedPrecipitation,
    required this.confidence,
    required this.source,
  });

  // TODO: Implement mapping
  factory ForecastDto.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('TODO: Implement fromJson');
  }

  Map<String, dynamic> toJson() {
    throw UnimplementedError('TODO: Implement toJson');
  }
}
