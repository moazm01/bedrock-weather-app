import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';

class AccelerometerService {
  StreamSubscription<UserAccelerometerEvent>? _subscription;
  DateTime? _lastPromptTime;
  final double shockThreshold = 25.0; // ~2.5G shock threshold

  void startListening({required Function() onShockDetected}) {
    try {
      _subscription?.cancel();
      _subscription = userAccelerometerEvents.listen(
        (UserAccelerometerEvent event) {
          final double magnitude = math.sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );

          if (magnitude > shockThreshold) {
            final now = DateTime.now();
            if (_lastPromptTime == null ||
                now.difference(_lastPromptTime!).inSeconds > 10) {
              _lastPromptTime = now;
              onShockDetected();
            }
          }
        },
        onError: (err) {
          // Suppress sensor stream errors on unsupported platforms
        },
        cancelOnError: false,
      );
    } catch (_) {
      // Suppress platform exceptions for sensors on web
    }
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}
