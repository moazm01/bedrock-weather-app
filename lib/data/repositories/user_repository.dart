import '../../domain/repositories/i_user_repository.dart';
import '../../domain/models/domain_models.dart';
import '../datasources/remote/firestore_user_datasource.dart';
import '../dto/user_dto.dart';

class UserRepository implements IUserRepository {
  final FirestoreUserDataSource _userDataSource;

  UserRepository(this._userDataSource);

  @override
  Future<UserProfileModel> getProfile(String uid) async {
    final userDto = await _userDataSource.getUserProfile(uid);
    if (userDto == null) {
      throw Exception('User profile not found for uid: $uid');
    }
    return userDto.toDomain();
  }

  @override
  Future<void> updateProfile(String uid, UserProfileModel profile) async {
    final userDto = UserDto(
      uid: profile.uid,
      username: profile.username,
      email: profile.email,
      tier: profile.tier,
      totalReports: profile.totalReports,
      verificationRate: profile.verificationRate,
      trustCoefficient: profile.trustCoefficient,
      avatarUrl: profile.avatarUrl,
    );
    await _userDataSource.updateUserProfile(uid, userDto.toFirestore());
  }

  Stream<UserProfileModel?> streamProfile(String uid) {
    return _userDataSource.streamUserProfile(uid).map((dto) => dto?.toDomain());
  }
}
