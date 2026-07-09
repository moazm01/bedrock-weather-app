import 'dart:async';
import 'package:flutter/material.dart';
import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService;

  double _latitude = 34.1558; // Abbottabad default
  double _longitude = 73.2194;
  bool _hasPermission = false;
  bool _isLoading = false;
  StreamSubscription<(double, double)>? _locationSubscription;

  LocationProvider(this._locationService) {
    _init();
  }

  double get latitude => _latitude;
  double get longitude => _longitude;
  bool get hasPermission => _hasPermission;
  bool get isLoading => _isLoading;

  Future<void> _init() async {
    // Check/request permission silently or set status
    _hasPermission = await _locationService.requestPermission();
    notifyListeners();
    await updateLocation();
  }

  Future<void> requestLocationPermission() async {
    _isLoading = true;
    notifyListeners();
    _hasPermission = await _locationService.requestPermission();
    _isLoading = false;
    notifyListeners();
    if (_hasPermission) {
      await updateLocation();
      startTracking();
    }
  }

  Future<void> updateLocation() async {
    _isLoading = true;
    notifyListeners();
    try {
      final coords = await _locationService.getCurrentLocation();
      _latitude = coords.$1;
      _longitude = coords.$2;
    } catch (_) {
      // Fallback already handled by service
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = _locationService.locationStream.listen(
      (coords) {
        _latitude = coords.$1;
        _longitude = coords.$2;
        notifyListeners();
      },
      onError: (_) {
        // Suppress location tracking exceptions on unsupported platforms / web
      },
    );
  }

  void stopTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}
