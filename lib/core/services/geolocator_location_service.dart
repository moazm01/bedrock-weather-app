import 'package:geolocator/geolocator.dart';
import 'location_service.dart';

class GeolocatorLocationService implements LocationService {
  // Abbottabad defaults
  static const double defaultLat = 34.1558;
  static const double defaultLng = 73.2194;

  @override
  Future<(double lat, double lng)> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return (defaultLat, defaultLng);
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return (defaultLat, defaultLng);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return (defaultLat, defaultLng);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      return (position.latitude, position.longitude);
    } catch (_) {
      return (defaultLat, defaultLng);
    }
  }

  @override
  Stream<(double lat, double lng)> get locationStream {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).map((position) => (position.latitude, position.longitude));
  }

  @override
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }
}
