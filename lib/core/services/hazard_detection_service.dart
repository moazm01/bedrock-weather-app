// Clean Architecture: Hazard Detection Service
import '../../domain/models/weather_report_model.dart';
import '../../domain/enums/domain_enums.dart';
import '../../data/datasources/remote/firestore_hazard_datasource.dart';
import '../../data/dto/hazard_dto.dart';
import '../utils/geohash_util.dart';

class HazardDetectionService {
  final FirestoreHazardDataSource _hazardDataSource;

  HazardDetectionService({FirestoreHazardDataSource? hazardDataSource})
      : _hazardDataSource = hazardDataSource ?? FirestoreHazardDataSource();

  // Configurable thresholds: {HazardType.flood: {'precipitation': 50.0, 'windSpeed': 80.0}}
  Map<HazardType, Map<String, double>> get thresholds => {
    HazardType.flood: {'precipitation': 50.0},
    HazardType.storm: {'windSpeed': 80.0},
    HazardType.landslide: {'precipitation': 75.0},
    HazardType.fog: {'humidity': 95.0},
  };

  // Rule-based + ML-based analysis: e.g., precipitation > 50mm/hr -> flood warning
  Future<List<HazardType>> analyzeWeatherForHazards(WeatherReport report) async {
    final List<HazardType> detected = [];
    final t = thresholds;

    if (report.precipitation >= (t[HazardType.flood]?['precipitation'] ?? 50.0)) {
      detected.add(HazardType.flood);
    }
    if (report.windSpeed >= (t[HazardType.storm]?['windSpeed'] ?? 80.0)) {
      detected.add(HazardType.storm);
    }
    if (report.humidity >= (t[HazardType.fog]?['humidity'] ?? 95.0) &&
        report.condition.toLowerCase().contains('fog')) {
      detected.add(HazardType.fog);
    }
    if (report.precipitation >= (t[HazardType.landslide]?['precipitation'] ?? 75.0)) {
      detected.add(HazardType.landslide);
    }

    return detected;
  }

  // Creates a system-generated hazard alert when weather thresholds are exceeded
  Future<void> triggerAutomaticAlert(HazardType type, WeatherReport trigger) async {
    final reportedAt = DateTime.now();
    final geohash = GeohashUtil.encode(trigger.latitude, trigger.longitude);
    final dto = HazardDto(
      id: '',
      type: type,
      description: 'Automated Alert: Extreme weather condition detected. '
          'Triggered by precipitation: ${trigger.precipitation}mm, wind: ${trigger.windSpeed}kph.',
      upvotes: 5,
      downvotes: 0,
      trustScore: 1.0,
      reporterName: 'System Alert',
      reporterTier: ReputationTier.veteran,
      reportedAt: reportedAt,
      latitude: trigger.latitude,
      longitude: trigger.longitude,
      geohash: geohash,
      reporterId: 'system_core',
    );

    await _hazardDataSource.submitHazard(dto, 'system_core');
  }
}
