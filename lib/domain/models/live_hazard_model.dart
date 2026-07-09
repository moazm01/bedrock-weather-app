// Clean Architecture: Live hazard events streamed from backend via WebSocket or Firestore snapshots
import 'domain_models.dart';

class LiveHazardEvent {
  final String eventType; // 'created', 'updated', 'resolved', 'escalated'
  final HazardDisplayModel hazard;
  final DateTime serverTimestamp;
  final String? updatedField;

  const LiveHazardEvent({
    required this.eventType,
    required this.hazard,
    required this.serverTimestamp,
    this.updatedField,
  });
}
