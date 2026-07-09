import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();

  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final connected = _isConnectedResult(results);
      _controller.add(connected);
    });
  }

  Stream<bool> get onConnectivityChanged => _controller.stream;

  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return _isConnectedResult(results);
  }

  bool _isConnectedResult(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    // If any of the connection types is not 'none', we are connected
    return results.any((result) => result != ConnectivityResult.none);
  }

  void dispose() {
    _controller.close();
  }
}
