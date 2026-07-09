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

class HazardRepository implements IHazardRepository {
  final FirestoreHazardDataSource _hazardDataSource;
  final LocalStorageService _localStorageService = LocalStorageService();
  final ConnectivityService _connectivityService = ConnectivityService();

  HazardRepository(this._hazardDataSource);

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
            imageUrl: h.imageUrl,
          ),
        );
      }
      return list;
    }

    try {
      final dtos = await _hazardDataSource.getNearbyHazards(lat, lng, radiusKm);
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

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
              imageUrl: h.imageUrl,
            ),
          );
        }
      } else {
        for (var dto in dtos) {
          final distance = _calculateDistance(
            lat,
            lng,
            dto.latitude,
            dto.longitude,
          );

          VoteState voteState = VoteState.none;
          if (currentUserId != null) {
            final vote = await _hazardDataSource.getUserVote(
              dto.id,
              currentUserId,
            );
            if (vote == 'up') voteState = VoteState.upvoted;
            if (vote == 'down') voteState = VoteState.downvoted;
          }

          list.add(
            dto.toDomain(
              distanceMeters: distance,
              currentUserVote: voteState,
              isOwnReport:
                  currentUserId != null &&
                  dto.reporterName ==
                      FirebaseAuth.instance.currentUser?.displayName,
            ),
          );
        }
      }

      await _localStorageService.cacheHazards(list);
      return list;
    } catch (_) {
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
            imageUrl: h.imageUrl,
          ),
        );
      }
      return list;
    }
  }

  @override
  Stream<List<HazardDisplayModel>> streamLiveHazards(double lat, double lng) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final userDisplayName = FirebaseAuth.instance.currentUser?.displayName;
    final controller = StreamController<List<HazardDisplayModel>>();

    _connectivityService.isConnected().then((online) async {
      if (!online) {
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
            imageUrl: h.imageUrl,
          );
        }).toList();
        controller.add(list);
        await controller.close();
      } else {
        StreamSubscription<List<HazardDto>>? subscription;
        subscription = _hazardDataSource.streamLiveHazards().listen(
          (dtos) async {
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
                    imageUrl: h.imageUrl,
                  ),
                );
              }
            } else {
              for (var dto in dtos) {
                final distance = _calculateDistance(
                  lat,
                  lng,
                  dto.latitude,
                  dto.longitude,
                );

                VoteState voteState = VoteState.none;
                if (currentUserId != null) {
                  final vote = await _hazardDataSource.getUserVote(
                    dto.id,
                    currentUserId,
                  );
                  if (vote == 'up') voteState = VoteState.upvoted;
                  if (vote == 'down') voteState = VoteState.downvoted;
                }

                list.add(
                  dto.toDomain(
                    distanceMeters: distance,
                    currentUserVote: voteState,
                    isOwnReport:
                        currentUserId != null &&
                        dto.reporterName == userDisplayName,
                  ),
                );
              }
            }
            await _localStorageService.cacheHazards(list);
            if (!controller.isClosed) {
              controller.add(list);
            }
          },
          onError: (err) async {
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
                imageUrl: h.imageUrl,
              );
            }).toList();
            if (!controller.isClosed) {
              controller.add(list);
              await controller.close();
            }
          },
        );

        controller.onCancel = () {
          subscription?.cancel();
        };
      }
    });

    return controller.stream;
  }

  @override
  Future<String> submitReport(HazardDisplayModel hazard) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
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
      imageUrl: hazard.imageUrl,
    );

    return await _hazardDataSource.submitHazard(dto, currentUserId);
  }

  @override
  Future<void> vote(String hazardId, bool isUpvote) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null)
      throw Exception('User must be logged in to vote');
    await _hazardDataSource.voteOnHazard(hazardId, currentUserId, isUpvote);
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
