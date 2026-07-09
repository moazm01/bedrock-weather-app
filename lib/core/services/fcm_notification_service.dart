import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';

class FcmNotificationService implements NotificationService {
  FirebaseMessaging? get _messaging {
    try {
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }

  final StreamController<Map<String, dynamic>> _onMessageController =
      StreamController<Map<String, dynamic>>.broadcast();

  @override
  Future<void> initialize() async {
    final msg = _messaging;
    if (msg == null) return;

    try {
      // Request permission (standard iOS/Android prompt)
      await msg.requestPermission(alert: true, badge: true, sound: true);

      // Foreground listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          _onMessageController.add({
            'title': message.notification?.title,
            'body': message.notification?.body,
            ...message.data,
          });
        } else {
          _onMessageController.add(message.data);
        }
      });

      // Background tap listener
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _onMessageController.add({
          'tapped': true,
          'title': message.notification?.title,
          'body': message.notification?.body,
          ...message.data,
        });
      });
    } catch (_) {}
  }

  @override
  Future<String?> getToken() async {
    final msg = _messaging;
    if (msg == null) return null;
    try {
      return await msg.getToken();
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<Map<String, dynamic>> get onMessage => _onMessageController.stream;

  @override
  Future<void> subscribeToTopic(String topic) async {
    final msg = _messaging;
    if (msg == null) return;
    try {
      await msg.subscribeToTopic(topic);
    } catch (_) {}
  }

  void dispose() {
    _onMessageController.close();
  }
}
