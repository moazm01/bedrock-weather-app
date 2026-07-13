import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class LoggerService {
  /// Log an error to both console (in debug mode) and Firebase Crashlytics.
  static void logError(dynamic error, StackTrace? stackTrace, {String? context}) {
    final message = '[ERROR]${context != null ? ' ($context)' : ''}: $error';
    debugPrint(message);
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }

    try {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: context,
        printDetails: false, // Already printed manually
      );
    } catch (_) {
      // Avoid crash if Firebase is not initialized
    }
  }

  /// Log an info message to console and Crashlytics custom logs.
  static void logInfo(String message) {
    debugPrint('[INFO]: $message');
    try {
      FirebaseCrashlytics.instance.log(message);
    } catch (_) {}
  }
}
