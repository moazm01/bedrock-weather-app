// Clean Architecture: Domain repository interface
import '../models/domain_models.dart';

abstract class IHazardRepository {
  Future<List<HazardDisplayModel>> getNearbyHazards(
    double lat,
    double lng,
    double radiusKm,
  );
  Future<String> submitReport(HazardDisplayModel hazard);
  Future<void> vote(String hazardId, bool isUpvote);
  Future<void> updateHazardImage(String hazardId, String imageUrl);
  Stream<List<HazardDisplayModel>> streamLiveHazards(double lat, double lng);
}
