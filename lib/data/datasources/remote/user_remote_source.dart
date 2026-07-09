// Clean Architecture: Remote Data Source
import '../../../domain/models/domain_models.dart';

class UserRemoteSource {
  Future<UserProfileModel> fetchProfile(String uid) {
    throw UnimplementedError('TODO: Implement');
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) {
    throw UnimplementedError('TODO: Implement');
  }
}
