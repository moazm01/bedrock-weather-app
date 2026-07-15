import 'package:flutter/material.dart';
import '../../domain/models/domain_models.dart';
import '../../data/repositories/earthquake_repository.dart';

class EarthquakeProvider extends ChangeNotifier {
  final EarthquakeRepository _earthquakeRepository;

  List<EarthquakeModel> _earthquakes = [];
  bool _isLoading = false;
  String? _errorMessage;

  EarthquakeProvider(this._earthquakeRepository);

  List<EarthquakeModel> get earthquakes => _earthquakes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUsingServerCache => _earthquakeRepository.isUsingServerCache;

  Future<void> fetchEarthquakes(double lat, double lng) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _earthquakes = await _earthquakeRepository.getRecentEarthquakes(lat, lng);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
