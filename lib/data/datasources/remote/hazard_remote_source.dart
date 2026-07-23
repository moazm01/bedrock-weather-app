// Clean Architecture: Remote Data Source
import '../../dto/hazard_dto.dart';

// TODO: Implement with Firestore real-time listeners or WebSocket
class HazardRemoteSource {
  Future<List<HazardDto>> fetchNearbyHazards(
    double lat,
    double lng,
    double radiusKm,
  ) {
    throw UnimplementedError('TODO: Implement');
  }

  Future<void> submitHazardReport(HazardDto hazard) {
    throw UnimplementedError('TODO: Implement');
  }

  Future<void> voteOnHazard(String hazardId, bool isUpvote) {
    throw UnimplementedError('TODO: Implement');
  }

  Stream<List<HazardDto>> streamLiveHazards(double lat, double lng) {
    throw UnimplementedError('TODO: Implement');
  }
}
