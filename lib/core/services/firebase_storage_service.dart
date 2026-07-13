/// Storage is disabled (Spark plan). All methods return null gracefully.
/// Re-enable by adding firebase_storage to pubspec and restoring the implementation.
class FirebaseStorageService {
  Future<String?> uploadHazardPhoto(String localPath, String hazardId) async => null;
  Future<String?> uploadUserAvatar(String localPath, String uid) async => null;
}
