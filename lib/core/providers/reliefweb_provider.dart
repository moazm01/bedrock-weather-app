import 'package:flutter/material.dart';
import '../../domain/models/domain_models.dart';
import '../../data/repositories/reliefweb_repository.dart';

class ReliefWebProvider extends ChangeNotifier {
  final ReliefWebRepository _reliefWebRepository;

  List<ReliefWebReportModel> _reports = [];
  bool _isLoading = false;
  String? _errorMessage;

  ReliefWebProvider(this._reliefWebRepository);

  List<ReliefWebReportModel> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUsingServerCache => _reliefWebRepository.isUsingServerCache;

  Future<void> fetchReports() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reports = await _reliefWebRepository.getRecentReports();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
