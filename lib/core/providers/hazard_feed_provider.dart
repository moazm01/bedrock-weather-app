import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/models/domain_models.dart';
import '../../data/repositories/hazard_repository.dart';
import '../services/firebase_storage_service.dart';

class HazardFeedProvider extends ChangeNotifier {
  final HazardRepository _hazardRepository;

  List<HazardDisplayModel> _hazards = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<HazardDisplayModel>>? _hazardsSubscription;

  HazardFeedProvider(this._hazardRepository);

  List<HazardDisplayModel> get hazards => _hazards;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Starts streaming active hazards based on current coordinates (to calculate distance).
  void startStreaming(double lat, double lng) {
    _hazardsSubscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _hazardsSubscription = _hazardRepository
        .streamLiveHazards(lat, lng)
        .listen(
          (data) {
            _hazards = data;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _isLoading = false;
            _errorMessage = error.toString();
            notifyListeners();
          },
        );
  }

  void stopStreaming() {
    _hazardsSubscription?.cancel();
    _hazardsSubscription = null;
    _hazards = [];
    notifyListeners();
  }

  Future<bool> submitReport(
    HazardDisplayModel hazard, {
    String? localImagePath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final docId = await _hazardRepository.submitReport(hazard);

      if (localImagePath != null) {
        final storageService = FirebaseStorageService();
        final downloadUrl = await storageService.uploadHazardPhoto(
          localImagePath,
          docId,
        );
        if (downloadUrl != null) {
          await _hazardRepository.updateHazardImage(docId, downloadUrl);
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> vote(String hazardId, bool isUpvote) async {
    try {
      await _hazardRepository.vote(hazardId, isUpvote);
      // Real-time stream will automatically trigger list updates.
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _hazardsSubscription?.cancel();
    super.dispose();
  }
}
