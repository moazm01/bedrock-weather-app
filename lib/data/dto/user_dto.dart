import '../../domain/models/domain_models.dart';
import '../../domain/enums/domain_enums.dart';

class UserDto {
  final String uid;
  final String username;
  final String email;
  final ReputationTier tier;
  final int totalReports;
  final double verificationRate;
  final double trustCoefficient;
  final String? avatarUrl;

  UserDto({
    required this.uid,
    required this.username,
    required this.email,
    required this.tier,
    required this.totalReports,
    required this.verificationRate,
    required this.trustCoefficient,
    this.avatarUrl,
  });

  factory UserDto.fromFirestore(Map<String, dynamic> data, String documentId) {
    return UserDto(
      uid: documentId,
      username: data['username'] as String? ?? 'Anonymous',
      email: data['email'] as String? ?? '',
      tier: _parseReputationTier(data['tier'] as String?),
      totalReports: data['totalReports'] as int? ?? 0,
      verificationRate: (data['verificationRate'] as num?)?.toDouble() ?? 0.0,
      trustCoefficient: (data['trustCoefficient'] as num?)?.toDouble() ?? 0.0,
      avatarUrl: data['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'email': email,
      'tier': tier.name,
      'totalReports': totalReports,
      'verificationRate': verificationRate,
      'trustCoefficient': trustCoefficient,
      'avatarUrl': avatarUrl,
    };
  }

  UserProfileModel toDomain() {
    return UserProfileModel(
      uid: uid,
      username: username,
      email: email,
      tier: tier,
      totalReports: totalReports,
      verificationRate: verificationRate,
      trustCoefficient: trustCoefficient,
      avatarUrl: avatarUrl,
    );
  }

  static ReputationTier _parseReputationTier(String? tierName) {
    if (tierName == null) return ReputationTier.rookie;
    return ReputationTier.values.firstWhere(
      (e) => e.name == tierName,
      orElse: () => ReputationTier.rookie,
    );
  }
}
