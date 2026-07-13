// Clean Architecture: Notification service
abstract class NotificationService {
  // TODO: Implement with firebase_messaging

  Future<void> initialize();
  Future<String?> getToken();
  Stream<Map<String, dynamic>> get onMessage;
  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);
}
