import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/domain_models.dart';
import '../../domain/enums/domain_enums.dart';
import '../../core/utils/geohash_util.dart';

class HazardDto {
  final String id;
  final HazardType type;
  final String description;
  final int upvotes;
  final int downvotes;
  final double trustScore;
  final String reporterName;
  final ReputationTier reporterTier;
  final DateTime reportedAt;
  final double latitude;
  final double longitude;
  final String geohash;
  final String? imageUrl;

  HazardDto({
    required this.id,
    required this.type,
    required this.description,
    required this.upvotes,
    required this.downvotes,
    required this.trustScore,
    required this.reporterName,
    required this.reporterTier,
    required this.reportedAt,
    required this.latitude,
    required this.longitude,
    required this.geohash,
    this.imageUrl,
  });

  factory HazardDto.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return HazardDto(
      id: documentId,
      type: _parseHazardType(data['type'] as String?),
      description: data['description'] as String? ?? '',
      upvotes: data['upvotes'] as int? ?? 0,
      downvotes: data['downvotes'] as int? ?? 0,
      trustScore: (data['trustScore'] as num?)?.toDouble() ?? 0.0,
      reporterName: data['reporterName'] as String? ?? 'Anonymous',
      reporterTier: _parseReputationTier(data['reporterTier'] as String?),
      reportedAt:
          (data['reportedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      geohash: data['geohash'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'description': description,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'trustScore': trustScore,
      'reporterName': reporterName,
      'reporterTier': reporterTier.name,
      'reportedAt': Timestamp.fromDate(reportedAt),
      'latitude': latitude,
      'longitude': longitude,
      'geohash': geohash.isEmpty
          ? GeohashUtil.encode(latitude, longitude)
          : geohash,
      'imageUrl': imageUrl,
    };
  }

  HazardDisplayModel toDomain({
    double distanceMeters = 0.0,
    VoteState currentUserVote = VoteState.none,
    bool isOwnReport = false,
  }) {
    return HazardDisplayModel(
      id: id,
      type: type,
      description: description,
      upvotes: upvotes,
      downvotes: downvotes,
      trustScore: trustScore,
      reporterName: reporterName,
      reporterTier: reporterTier,
      reportedAt: reportedAt,
      latitude: latitude,
      longitude: longitude,
      distanceMeters: distanceMeters,
      currentUserVote: currentUserVote,
      isOwnReport: isOwnReport,
      imageUrl: imageUrl,
    );
  }

  static HazardType _parseHazardType(String? typeName) {
    if (typeName == null) return HazardType.accident;
    return HazardType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => HazardType.accident,
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
