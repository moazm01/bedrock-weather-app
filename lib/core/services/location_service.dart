// Clean Architecture: Location service
abstract class LocationService {
  // TODO: Implement with geolocator package

  Future<(double lat, double lng)> getCurrentLocation();
  Stream<(double lat, double lng)> get locationStream;
  Future<bool> requestPermission();
}
