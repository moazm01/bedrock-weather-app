import '../../domain/repositories/i_earthquake_repository.dart';
import '../../domain/models/domain_models.dart';
import '../datasources/remote/usgs_earthquake_datasource.dart';

class EarthquakeRepository implements IEarthquakeRepository {
  final UsgsEarthquakeDataSource _earthquakeDataSource;

  EarthquakeRepository(this._earthquakeDataSource);

  @override
  Future<List<EarthquakeModel>> getRecentEarthquakes(
    double lat,
    double lng,
  ) async {
    final features = await _earthquakeDataSource.fetchEarthquakes(lat, lng);
    final List<EarthquakeModel> list = [];

    for (final f in features) {
      final id = f['id'] as String? ?? '';
      final props = f['properties'] as Map<String, dynamic>? ?? {};
      final geom = f['geometry'] as Map<String, dynamic>? ?? {};
      final coords = geom['coordinates'] as List<dynamic>? ?? [0.0, 0.0, 0.0];

      final double magnitude = (props['mag'] as num?)?.toDouble() ?? 0.0;
      final String place = props['place'] as String? ?? 'Unknown Location';
      final int timeEpoch = props['time'] as int? ?? 0;
      final DateTime time = DateTime.fromMillisecondsSinceEpoch(timeEpoch);
      final String url = props['url'] as String? ?? '';

      final double longitude = (coords[0] as num).toDouble();
      final double latitude = (coords[1] as num).toDouble();
      final double depth = (coords.length > 2)
          ? (coords[2] as num).toDouble()
          : 0.0;

      list.add(
        EarthquakeModel(
          id: id,
          magnitude: magnitude,
          place: place,
          time: time,
          latitude: latitude,
          longitude: longitude,
          depth: depth,
          url: url,
        ),
      );
    }
    return list;
  }
}
