import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/domain_models.dart';
import '../../domain/enums/domain_enums.dart';

class LocalStorageService {
  static const String _keyHazards = 'cached_hazards';

  Future<void> cacheHazards(List<HazardDisplayModel> hazards) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList = hazards.map((h) {
        return {
          'id': h.id,
          'type': h.type.name,
          'description': h.description,
          'upvotes': h.upvotes,
          'downvotes': h.downvotes,
          'trustScore': h.trustScore,
          'reporterName': h.reporterName,
          'reporterTier': h.reporterTier.name,
          'reportedAt': h.reportedAt.toIso8601String(),
          'latitude': h.latitude,
          'longitude': h.longitude,
          'imageUrl': h.imageUrl,
        };
      }).toList();
      await prefs.setString(_keyHazards, json.encode(jsonList));
    } catch (_) {}
  }

  Future<List<HazardDisplayModel>> getCachedHazards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_keyHazards);
      if (jsonStr == null || jsonStr.isEmpty) return [];

      final List<dynamic> decoded = json.decode(jsonStr) as List<dynamic>;
      return decoded.map((item) {
        final data = item as Map<String, dynamic>;
        return HazardDisplayModel(
          id: data['id'] as String? ?? '',
          type: _parseHazardType(data['type'] as String?),
          description: data['description'] as String? ?? '',
          upvotes: data['upvotes'] as int? ?? 0,
          downvotes: data['downvotes'] as int? ?? 0,
          trustScore: (data['trustScore'] as num?)?.toDouble() ?? 0.0,
          reporterName: data['reporterName'] as String? ?? 'Anonymous',
          reporterTier: _parseReputationTier(data['reporterTier'] as String?),
          reportedAt: DateTime.parse(data['reportedAt'] as String),
          latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
          distanceMeters: 0.0,
          currentUserVote: VoteState.none,
          isOwnReport: false,
          imageUrl: data['imageUrl'] as String?,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  HazardType _parseHazardType(String? typeName) {
    if (typeName == null) return HazardType.accident;
    return HazardType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => HazardType.accident,
    );
  }

  ReputationTier _parseReputationTier(String? tierName) {
    if (tierName == null) return ReputationTier.rookie;
    return ReputationTier.values.firstWhere(
      (e) => e.name == tierName,
      orElse: () => ReputationTier.rookie,
    );
  }
}
