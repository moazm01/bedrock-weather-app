import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/i_hazard_repository.dart';
import '../../domain/models/domain_models.dart';
import '../../domain/enums/domain_enums.dart';
import '../datasources/remote/firestore_hazard_datasource.dart';
import '../dto/hazard_dto.dart';
import '../../core/utils/geohash_util.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/services/logger_service.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class HazardRepository implements IHazardRepository {
  final FirestoreHazardDataSource _hazardDataSource;
  final LocalStorageService _localStorageService = LocalStorageService();
  final ConnectivityService _connectivityService;
  final String? Function() _currentUserIdProvider;
  final FirebasePerformance? _performance;
  final FirebaseAnalytics? _analytics;

  HazardRepository(
    this._hazardDataSource, {
    String? Function()? currentUserIdProvider,
    FirebasePerformance? performance,
    FirebaseAnalytics? analytics,
    ConnectivityService? connectivityService,
  })  : _currentUserIdProvider = currentUserIdProvider ?? (() => FirebaseAuth.instance.currentUser?.uid),
        _performance = performance,
        _analytics = analytics,
        _connectivityService = connectivityService ?? ConnectivityService();

  List<HazardDisplayModel> _getMockHazards() {
    return [
      HazardDisplayModel(
        id: 'mock_hazard_1',
        type: HazardType.landslide,
        description:
            'Landslide blocked PMA Road near Kakul. Main access restricted.',
        upvotes: 8,
        downvotes: 1,
        trustScore: 0.88,
        reporterName: 'Khurram Shehzad',
        reporterTier: ReputationTier.veteran,
        reportedAt: DateTime.now().subtract(const Duration(hours: 1)),
        latitude: 34.1958,
        longitude: 73.2594,
        distanceMeters: 0.0,
        currentUserVote: VoteState.none,
        isOwnReport: false,
        reporterId: 'mock_reporter_1',
        imageUrl: null,
      ),
      HazardDisplayModel(
        id: 'mock_hazard_2',
        type: HazardType.flood,
        description:
            'Severe monsoon flooding on Karakoram Highway near Ayub Medical College.',
        upvotes: 15,
        downvotes: 2,
        trustScore: 0.88,
        reporterName: 'Dr. Ayesha Malik',
        reporterTier: ReputationTier.expert,
        reportedAt: DateTime.now().subtract(const Duration(hours: 2)),
        latitude: 34.1758,
        longitude: 73.2294,
        distanceMeters: 0.0,
        currentUserVote: VoteState.none,
        isOwnReport: false,
        reporterId: 'mock_reporter_2',
        imageUrl: null,
      ),
      HazardDisplayModel(
        id: 'mock_hazard_3',
        type: HazardType.fog,
        description:
            'Zero visibility fog early morning at Shimla Hill viewpoint. Caution advised.',
        upvotes: 4,
        downvotes: 0,
        trustScore: 1.0,
        reporterName: 'Zainab Qazi',
        reporterTier: ReputationTier.trusted,
        reportedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        latitude: 34.1558,
        longitude: 73.1994,
        distanceMeters: 0.0,
        currentUserVote: VoteState.none,
        isOwnReport: false,
        reporterId: 'mock_reporter_3',
        imageUrl: null,
      ),
      HazardDisplayModel(
        id: 'mock_hazard_4',
        type: HazardType.roadBlock,
        description:
            'Sewerage construction causing a complete road block near Main Bazar Abbottabad.',
        upvotes: 6,
        downvotes: 1,
        trustScore: 0.85,
        reporterName: 'Hamza Khan',
        reporterTier: ReputationTier.rookie,
        reportedAt: DateTime.now().subtract(const Duration(hours: 3)),
        latitude: 34.1480,
        longitude: 73.1980,
        distanceMeters: 0.0,
        currentUserVote: VoteState.none,
        isOwnReport: false,
        reporterId: 'mock_reporter_4',
        imageUrl: null,
      ),
      HazardDisplayModel(
        id: 'mock_hazard_5',
        type: HazardType.accident,
        description:
            'Multi-vehicle collision near Abbottabad Public School (APS). Lane closed.',
        upvotes: 9,
        downvotes: 3,
        trustScore: 0.75,
        reporterName: 'Sajid Abbasi',
        reporterTier: ReputationTier.veteran,
        reportedAt: DateTime.now().subtract(const Duration(hours: 4)),
        latitude: 34.1680,
        longitude: 73.2380,
        distanceMeters: 0.0,
        currentUserVote: VoteState.none,
        isOwnReport: false,
        reporterId: 'mock_reporter_5',
        imageUrl: null,
      ),
    ];
  }

  @override
  Future<List<HazardDisplayModel>> getNearbyHazards(
    double lat,
    double lng,
    double radiusKm,
  ) async {
    final performance = _performance ?? FirebasePerformance.instance;
    final trace = performance.newTrace('fetch_nearby_hazards');
    await trace.start();
    try {
      final bool online = await _connectivityService.isConnected();
      if (!online) {
        var cached = await _localStorageService.getCachedHazards();
        if (cached.isEmpty) {
          cached = _getMockHazards();
          await _localStorageService.cacheHazards(cached);
        }
        final List<HazardDisplayModel> list = [];
        for (var h in cached) {
          final distance = _calculateDistance(lat, lng, h.latitude, h.longitude);
          list.add(
            HazardDisplayModel(
              id: h.id,
              type: h.type,
              description: h.description,
              upvotes: h.upvotes,
              downvotes: h.downvotes,
              trustScore: h.trustScore,
              reporterName: h.reporterName,
              reporterTier: h.reporterTier,
              reportedAt: h.reportedAt,
              latitude: h.latitude,
              longitude: h.longitude,
              distanceMeters: distance,
              currentUserVote: h.currentUserVote,
              isOwnReport: h.isOwnReport,
              reporterId: h.reporterId,
              imageUrl: h.imageUrl,
            ),
          );
        }
        await trace.stop();
        return list;
      }

      try {
        final dtos = await _hazardDataSource.getNearbyHazards(lat, lng, radiusKm);
        final currentUserId = _currentUserIdProvider();

        final List<HazardDisplayModel> list = [];
        if (dtos.isEmpty) {
          final cached = _getMockHazards();
          for (var h in cached) {
            final distance = _calculateDistance(
              lat,
              lng,
              h.latitude,
              h.longitude,
            );
            list.add(
              HazardDisplayModel(
                id: h.id,
                type: h.type,
                description: h.description,
                upvotes: h.upvotes,
                downvotes: h.downvotes,
                trustScore: h.trustScore,
                reporterName: h.reporterName,
                reporterTier: h.reporterTier,
                reportedAt: h.reportedAt,
                latitude: h.latitude,
                longitude: h.longitude,
                distanceMeters: distance,
                currentUserVote: h.currentUserVote,
                isOwnReport: h.isOwnReport,
                reporterId: h.reporterId,
                imageUrl: h.imageUrl,
              ),
            );
          }
        } else {
          final Map<String, String> userVotes = currentUserId != null
              ? await _hazardDataSource.getUserVotes(currentUserId)
              : {};

          for (var dto in dtos) {
            final distance = _calculateDistance(
              lat,
              lng,
              dto.latitude,
              dto.longitude,
            );

            VoteState voteState = VoteState.none;
            final userVote = userVotes[dto.id];
            if (userVote == 'up') voteState = VoteState.upvoted;
            if (userVote == 'down') voteState = VoteState.downvoted;

            list.add(
              dto.toDomain(
                distanceMeters: distance,
                currentUserVote: voteState,
                isOwnReport:
                    currentUserId != null &&
                    dto.reporterId == currentUserId,
              ),
            );
          }
        }

        await _localStorageService.cacheHazards(list);
        await trace.stop();
        return list;
      } catch (e, stack) {
        LoggerService.logError(e, stack, context: 'getNearbyHazardsInner');
        var cached = await _localStorageService.getCachedHazards();
        if (cached.isEmpty) {
          cached = _getMockHazards();
          await _localStorageService.cacheHazards(cached);
        }
        final List<HazardDisplayModel> list = [];
        for (var h in cached) {
          final distance = _calculateDistance(lat, lng, h.latitude, h.longitude);
          list.add(
            HazardDisplayModel(
              id: h.id,
              type: h.type,
              description: h.description,
              upvotes: h.upvotes,
              downvotes: h.downvotes,
              trustScore: h.trustScore,
              reporterName: h.reporterName,
              reporterTier: h.reporterTier,
              reportedAt: h.reportedAt,
              latitude: h.latitude,
              longitude: h.longitude,
              distanceMeters: distance,
              currentUserVote: h.currentUserVote,
              isOwnReport: h.isOwnReport,
              reporterId: h.reporterId,
              imageUrl: h.imageUrl,
            ),
          );
        }
        await trace.stop();
        return list;
      }
    } catch (e, stack) {
      LoggerService.logError(e, stack, context: 'getNearbyHazardsOuter');
      await trace.stop();
      return [];
    }
  }

  @override
  Stream<List<HazardDisplayModel>> streamLiveHazards(double lat, double lng) async* {
    final currentUserId = _currentUserIdProvider();
    final isOnline = await _connectivityService.isConnected();

    if (!isOnline) {
      var cached = await _localStorageService.getCachedHazards();
      if (cached.isEmpty) {
        cached = _getMockHazards();
        await _localStorageService.cacheHazards(cached);
      }
      final List<HazardDisplayModel> list = cached.map((h) {
        final distance = _calculateDistance(
          lat,
          lng,
          h.latitude,
          h.longitude,
        );
        return HazardDisplayModel(
          id: h.id,
          type: h.type,
          description: h.description,
          upvotes: h.upvotes,
          downvotes: h.downvotes,
          trustScore: h.trustScore,
          reporterName: h.reporterName,
          reporterTier: h.reporterTier,
          reportedAt: h.reportedAt,
          latitude: h.latitude,
          longitude: h.longitude,
          distanceMeters: distance,
          currentUserVote: h.currentUserVote,
          isOwnReport: h.isOwnReport,
          reporterId: h.reporterId,
          imageUrl: h.imageUrl,
        );
      }).toList();
      yield list;
      return;
    }

    try {
      await for (final dtos in _hazardDataSource.streamLiveHazards()) {
        final List<HazardDisplayModel> list = [];
        if (dtos.isEmpty) {
          final cached = _getMockHazards();
          for (var h in cached) {
            final distance = _calculateDistance(
              lat,
              lng,
              h.latitude,
              h.longitude,
            );
            list.add(
              HazardDisplayModel(
                id: h.id,
                type: h.type,
                description: h.description,
                upvotes: h.upvotes,
                downvotes: h.downvotes,
                trustScore: h.trustScore,
                reporterName: h.reporterName,
                reporterTier: h.reporterTier,
                reportedAt: h.reportedAt,
                latitude: h.latitude,
                longitude: h.longitude,
                distanceMeters: distance,
                currentUserVote: h.currentUserVote,
                isOwnReport: h.isOwnReport,
                reporterId: h.reporterId,
                imageUrl: h.imageUrl,
              ),
            );
          }
        } else {
          final Map<String, String> userVotes = currentUserId != null
              ? await _hazardDataSource.getUserVotes(currentUserId)
              : {};

          for (var dto in dtos) {
            final distance = _calculateDistance(
              lat,
              lng,
              dto.latitude,
              dto.longitude,
            );

            VoteState voteState = VoteState.none;
            final userVote = userVotes[dto.id];
            if (userVote == 'up') voteState = VoteState.upvoted;
            if (userVote == 'down') voteState = VoteState.downvoted;

            list.add(
              dto.toDomain(
                distanceMeters: distance,
                currentUserVote: voteState,
                isOwnReport:
                    currentUserId != null &&
                    dto.reporterId == currentUserId,
              ),
            );
          }
        }
        await _localStorageService.cacheHazards(list);
        yield list;
      }
    } catch (e, stack) {
      LoggerService.logError(e, stack, context: 'streamLiveHazards');
      var cached = await _localStorageService.getCachedHazards();
      if (cached.isEmpty) {
        cached = _getMockHazards();
      }
      yield cached.map((h) {
        final distance = _calculateDistance(
          lat,
          lng,
          h.latitude,
          h.longitude,
        );
        return HazardDisplayModel(
          id: h.id,
          type: h.type,
          description: h.description,
          upvotes: h.upvotes,
          downvotes: h.downvotes,
          trustScore: h.trustScore,
          reporterName: h.reporterName,
          reporterTier: h.reporterTier,
          reportedAt: h.reportedAt,
          latitude: h.latitude,
          longitude: h.longitude,
          distanceMeters: distance,
          currentUserVote: h.currentUserVote,
          isOwnReport: h.isOwnReport,
          reporterId: h.reporterId,
          imageUrl: h.imageUrl,
        );
      }).toList();
    }
  }

  @override
  Future<String> submitReport(HazardDisplayModel hazard) async {
    final currentUserId = _currentUserIdProvider();
    if (currentUserId == null)
      throw Exception('User must be logged in to submit a report');

    final geohash = GeohashUtil.encode(hazard.latitude, hazard.longitude);
    final dto = HazardDto(
      id: hazard.id,
      type: hazard.type,
      description: hazard.description,
      upvotes: hazard.upvotes,
      downvotes: hazard.downvotes,
      trustScore: hazard.trustScore,
      reporterName: hazard.reporterName,
      reporterTier: hazard.reporterTier,
      reportedAt: hazard.reportedAt,
      latitude: hazard.latitude,
      longitude: hazard.longitude,
      geohash: geohash,
      reporterId: currentUserId,
      imageUrl: hazard.imageUrl,
    );

    final docId = await _hazardDataSource.submitHazard(dto, currentUserId);

    try {
      final analytics = _analytics ?? FirebaseAnalytics.instance;
      analytics.logEvent(
        name: 'submit_hazard_report',
        parameters: {
          'hazard_type': hazard.type.name,
          'latitude': hazard.latitude,
          'longitude': hazard.longitude,
        },
      );
    } catch (_) {}

    return docId;
  }

  @override
  Future<void> vote(String hazardId, bool isUpvote) async {
    final currentUserId = _currentUserIdProvider();
    if (currentUserId == null)
      throw Exception('User must be logged in to vote');
    await _hazardDataSource.voteOnHazard(hazardId, currentUserId, isUpvote);

    try {
      final analytics = _analytics ?? FirebaseAnalytics.instance;
      analytics.logEvent(
        name: 'vote_hazard',
        parameters: {
          'hazard_id': hazardId,
          'vote_type': isUpvote ? 'upvote' : 'downvote',
        },
      );
    } catch (_) {}
  }

  // Haversine distance formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    const earthRadiusMeters = 6371000.0;
    return earthRadiusMeters * c;
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180.0);
  }
}
