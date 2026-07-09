import '../enums/domain_enums.dart';

// Plain Dart model representing an active crowdsourced warning report in Abbottabad.
// Fields are marked 'final' and the constructor 'const' to enforce immutability,
// which is a software engineering best practice that prevents unintended side-effects.
// Reference: https://dart.dev/language/classes
class HazardDisplayModel {
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
  final double distanceMeters;
  final VoteState currentUserVote;
  final bool isOwnReport;
  final String? imageUrl;

  const HazardDisplayModel({
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
    required this.distanceMeters,
    required this.currentUserVote,
    required this.isOwnReport,
    this.imageUrl,
  });

  // Business logic getter that determines the status state dynamically.
  SafetyStatus get safetyStatus {
    if (trustScore >= 0.75 && downvotes < 3) return SafetyStatus.critical;
    if (trustScore >= 0.40) return SafetyStatus.caution;
    return SafetyStatus.safe;
  }
}

// Plain Dart class representing the active user's credentials and score attributes.
class UserProfileModel {
  final String uid;
  final String username;
  final String email;
  final ReputationTier tier;
  final int totalReports;
  final double verificationRate; // 0.0 to 1.0
  final double trustCoefficient;
  final String? avatarUrl;

  const UserProfileModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.tier,
    required this.totalReports,
    required this.verificationRate,
    required this.trustCoefficient,
    this.avatarUrl,
  });
}

// Model containing static text segments displaying inside the onboarding PageView slides.
class OnboardingStepModel {
  final String title;
  final String description;
  final String iconAsset;

  const OnboardingStepModel({
    required this.title,
    required this.description,
    required this.iconAsset,
  });
}

class EarthquakeModel {
  final String id;
  final double magnitude;
  final String place;
  final DateTime time;
  final double latitude;
  final double longitude;
  final double depth;
  final String url;

  const EarthquakeModel({
    required this.id,
    required this.magnitude,
    required this.place,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.depth,
    required this.url,
  });
}

class ReliefWebReportModel {
  final String id;
  final String title;
  final String source;
  final DateTime date;
  final String url;

  const ReliefWebReportModel({
    required this.id,
    required this.title,
    required this.source,
    required this.date,
    required this.url,
  });
}
