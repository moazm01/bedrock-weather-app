import 'package:cloud_firestore/cloud_firestore.dart';
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
  final DateTime? createdAt;
  final bool isBanned;
  final String? fcmToken;
  final String? bio;
  final DateTime? birthdate;
  final List<String> followers;
  final List<String> following;

  UserDto({
    required this.uid,
    required this.username,
    required this.email,
    required this.tier,
    required this.totalReports,
    required this.verificationRate,
    required this.trustCoefficient,
    this.avatarUrl,
    this.createdAt,
    this.isBanned = false,
    this.fcmToken,
    this.bio,
    this.birthdate,
    this.followers = const [],
    this.following = const [],
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
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      isBanned: data['isBanned'] as bool? ?? false,
      fcmToken: data['fcmToken'] as String?,
      bio: data['bio'] as String?,
      birthdate: (data['birthdate'] as Timestamp?)?.toDate(),
      followers: (data['followers'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      following: (data['following'] as List?)?.map((e) => e.toString()).toList() ?? const [],
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
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'isBanned': isBanned,
      'fcmToken': fcmToken,
      'bio': bio,
      'birthdate': birthdate != null ? Timestamp.fromDate(birthdate!) : null,
      'followers': followers,
      'following': following,
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
      createdAt: createdAt,
      isBanned: isBanned,
      fcmToken: fcmToken,
      bio: bio,
      birthdate: birthdate,
      followers: followers,
      following: following,
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
