// Clean Architecture: Domain repository interface
import '../models/domain_models.dart';

abstract class IUserRepository {
  Future<UserProfileModel> getProfile(String uid);
  Future<void> updateProfile(String uid, UserProfileModel profile);
}
