import '../models/domain_models.dart';

abstract class IEarthquakeRepository {
  Future<List<EarthquakeModel>> getRecentEarthquakes(double lat, double lng);
  bool get isUsingServerCache;
}
