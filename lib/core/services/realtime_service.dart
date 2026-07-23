// Clean Architecture: Realtime Service
// TODO: Implement WebSocket or Firebase Realtime Database connection
abstract class RealtimeService {
  Future<void> connect();
  Future<void> disconnect();
  Stream<Map<String, dynamic>> get eventStream;
  bool get isConnected;
}
