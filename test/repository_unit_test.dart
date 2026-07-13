import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:bedrock_phase1/data/repositories/user_repository.dart';
import 'package:bedrock_phase1/data/repositories/hazard_repository.dart';
import 'package:bedrock_phase1/data/repositories/weather_repository.dart';
import 'package:bedrock_phase1/data/datasources/remote/firestore_user_datasource.dart';
import 'package:bedrock_phase1/data/datasources/remote/firestore_hazard_datasource.dart';
import 'package:bedrock_phase1/data/datasources/remote/open_meteo_datasource.dart';
import 'package:bedrock_phase1/domain/models/domain_models.dart';
import 'package:bedrock_phase1/domain/enums/domain_enums.dart';
import 'package:bedrock_phase1/data/dto/user_dto.dart';
import 'package:bedrock_phase1/data/dto/hazard_dto.dart';
import 'package:bedrock_phase1/core/services/connectivity_service.dart';

class FakeFirebasePerformance extends Fake implements FirebasePerformance {
  @override
  Trace newTrace(String name) => FakeTrace(name);
}

class FakeTrace extends Fake implements Trace {
  final String name;
  FakeTrace(this.name);

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}

class FakeFirebaseAnalytics extends Fake implements FirebaseAnalytics {
  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {}
}

class FakeConnectivityService extends Fake implements ConnectivityService {
  final bool isOnline;
  FakeConnectivityService({this.isOnline = true});

  @override
  Future<bool> isConnected() async => isOnline;

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(isOnline);
}

class FakeFirestoreUserDataSource implements FirestoreUserDataSource {
  final Map<String, UserDto> db = {};

  @override
  Future<UserDto?> getUserProfile(String uid) async {
    return db[uid];
  }

  @override
  Future<void> createUserProfile(String uid, String email, String username) async {
    db[uid] = UserDto(
      uid: uid,
      username: username,
      email: email,
      tier: ReputationTier.rookie,
      totalReports: 0,
      verificationRate: 0.0,
      trustCoefficient: 0.0,
      createdAt: DateTime.now(),
      isBanned: false,
    );
  }

  @override
  Future<void> updateUserProfile(String uid, Map<String, dynamic> fields) async {
    final existing = db[uid];
    if (existing != null) {
      db[uid] = UserDto(
        uid: uid,
        username: fields['username'] as String? ?? existing.username,
        email: fields['email'] as String? ?? existing.email,
        tier: ReputationTier.values.firstWhere(
          (t) => t.name == (fields['tier'] as String?),
          orElse: () => existing.tier,
        ),
        totalReports: fields['totalReports'] as int? ?? existing.totalReports,
        verificationRate: (fields['verificationRate'] as num?)?.toDouble() ?? existing.verificationRate,
        trustCoefficient: (fields['trustCoefficient'] as num?)?.toDouble() ?? existing.trustCoefficient,
        avatarUrl: fields['avatarUrl'] as String? ?? existing.avatarUrl,
        createdAt: existing.createdAt,
        isBanned: fields['isBanned'] as bool? ?? existing.isBanned,
        fcmToken: fields['fcmToken'] as String? ?? existing.fcmToken,
      );
    }
  }

  @override
  Stream<UserDto?> streamUserProfile(String uid) {
    return Stream.value(db[uid]);
  }
}

class FakeFirestoreHazardDataSource implements FirestoreHazardDataSource {
  final Map<String, HazardDto> hazardsDb = {};
  final Map<String, String> userVotes = {};

  @override
  Future<String> submitHazard(HazardDto hazard, String userId) async {
    final docId = 'hazard_${hazardsDb.length + 1}';
    hazardsDb[docId] = HazardDto(
      id: docId,
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
      geohash: hazard.geohash,
      reporterId: userId,
      imageUrl: hazard.imageUrl,
    );
    return docId;
  }

  @override
  Stream<List<HazardDto>> streamLiveHazards() {
    return Stream.value(hazardsDb.values.toList());
  }

  @override
  Future<List<HazardDto>> getNearbyHazards(double lat, double lng, double radiusKm) async {
    return hazardsDb.values.toList();
  }

  @override
  Future<void> voteOnHazard(String hazardId, String userId, bool isUpvote) async {
    final existing = hazardsDb[hazardId];
    if (existing != null) {
      final voteKey = '${hazardId}_$userId';
      final existingVote = userVotes[voteKey];
      final targetVote = isUpvote ? 'up' : 'down';
      
      int upvotes = existing.upvotes;
      int downvotes = existing.downvotes;

      if (existingVote == targetVote) {
        if (isUpvote) {
          upvotes = (upvotes - 1).clamp(0, 9999);
        } else {
          downvotes = (downvotes - 1).clamp(0, 9999);
        }
        userVotes.remove(voteKey);
      } else {
        if (existingVote == 'up') {
          upvotes = (upvotes - 1).clamp(0, 9999);
        } else if (existingVote == 'down') {
          downvotes = (downvotes - 1).clamp(0, 9999);
        }
        if (isUpvote) {
          upvotes++;
        } else {
          downvotes++;
        }
        userVotes[voteKey] = targetVote;
      }

      double trustScore = 0.0;
      if (upvotes + downvotes > 0) {
        trustScore = upvotes / (upvotes + downvotes);
      }

      hazardsDb[hazardId] = HazardDto(
        id: existing.id,
        type: existing.type,
        description: existing.description,
        upvotes: upvotes,
        downvotes: downvotes,
        trustScore: trustScore,
        reporterName: existing.reporterName,
        reporterTier: existing.reporterTier,
        reportedAt: existing.reportedAt,
        latitude: existing.latitude,
        longitude: existing.longitude,
        geohash: existing.geohash,
        reporterId: existing.reporterId,
        imageUrl: existing.imageUrl,
      );
    }
  }

  @override
  Future<String?> getUserVote(String hazardId, String userId) async {
    return userVotes['${hazardId}_$userId'];
  }

  @override
  Future<Map<String, String>> getUserVotes(String userId) async {
    final Map<String, String> result = {};
    userVotes.forEach((key, value) {
      if (key.endsWith('_$userId')) {
        final parts = key.split('_');
        final hazardId = parts[0];
        result[hazardId] = value;
      }
    });
    return result;
  }

  @override
  Future<void> resolveHazard(String hazardId, String resolvedById) async {
    final existing = hazardsDb[hazardId];
    if (existing != null) {
      hazardsDb[hazardId] = HazardDto(
        id: existing.id,
        type: existing.type,
        description: existing.description,
        upvotes: existing.upvotes,
        downvotes: existing.downvotes,
        trustScore: existing.trustScore,
        reporterName: existing.reporterName,
        reporterTier: existing.reporterTier,
        reportedAt: existing.reportedAt,
        latitude: existing.latitude,
        longitude: existing.longitude,
        geohash: existing.geohash,
        reporterId: existing.reporterId,
        imageUrl: existing.imageUrl,
      );
    }
  }
}

class FakeOpenMeteoWeatherDataSource implements OpenMeteoWeatherDataSource {
  @override
  Future<Map<String, dynamic>> fetchWeatherData(double lat, double lng) async {
    return {
      'latitude': lat,
      'longitude': lng,
      'current': {
        'temperature_2m': 24.5,
        'relative_humidity_2m': 65,
        'apparent_temperature': 25.0,
        'precipitation': 0.0,
        'surface_pressure': 1013.2,
        'wind_speed_10m': 12.4,
        'weather_code': 1,
        'visibility': 10000.0,
      },
      'hourly': {
        'time': ['2026-07-10T14:00', '2026-07-10T15:00'],
        'temperature_2m': [24.5, 23.8],
        'weather_code': [1, 2],
        'precipitation_probability': [10, 20],
      },
      'daily': {
        'time': ['2026-07-10'],
        'weather_code': [1],
        'temperature_2m_max': [28.0],
        'temperature_2m_min': [19.0],
        'precipitation_probability_max': [30],
      }
    };
  }
}

void main() {
  group('UserRepository Tests', () {
    late FakeFirestoreUserDataSource fakeUserDataSource;
    late UserRepository userRepository;

    setUp(() {
      fakeUserDataSource = FakeFirestoreUserDataSource();
      userRepository = UserRepository(fakeUserDataSource);
    });

    test('createUserProfile registers a user with rookie tier', () async {
      await fakeUserDataSource.createUserProfile('user_123', 'test@test.com', 'TestUser');
      
      final profile = await userRepository.getProfile('user_123');
      expect(profile.uid, 'user_123');
      expect(profile.email, 'test@test.com');
      expect(profile.username, 'TestUser');
      expect(profile.tier, ReputationTier.rookie);
      expect(profile.isBanned, false);
    });

    test('updateProfile modifies user details correctly', () async {
      await fakeUserDataSource.createUserProfile('user_123', 'test@test.com', 'TestUser');
      
      final updatedProfile = UserProfileModel(
        uid: 'user_123',
        username: 'NewUsername',
        email: 'test@test.com',
        tier: ReputationTier.trusted,
        totalReports: 10,
        verificationRate: 0.85,
        trustCoefficient: 0.90,
        createdAt: DateTime.now(),
        isBanned: false,
        fcmToken: 'token_abc',
      );

      await userRepository.updateProfile('user_123', updatedProfile);
      
      final retrieved = await userRepository.getProfile('user_123');
      expect(retrieved.username, 'NewUsername');
      expect(retrieved.tier, ReputationTier.trusted);
      expect(retrieved.totalReports, 10);
      expect(retrieved.fcmToken, 'token_abc');
    });
  });

  group('HazardRepository Tests', () {
    late FakeFirestoreHazardDataSource fakeHazardDataSource;
    late HazardRepository hazardRepository;
    late FakeFirebasePerformance fakePerformance;
    late FakeFirebaseAnalytics fakeAnalytics;
    late FakeConnectivityService fakeConnectivityService;

    setUp(() {
      fakeHazardDataSource = FakeFirestoreHazardDataSource();
      fakePerformance = FakeFirebasePerformance();
      fakeAnalytics = FakeFirebaseAnalytics();
      fakeConnectivityService = FakeConnectivityService(isOnline: true);
      
      hazardRepository = HazardRepository(
        fakeHazardDataSource,
        currentUserIdProvider: () => 'user_a',
        performance: fakePerformance,
        analytics: fakeAnalytics,
        connectivityService: fakeConnectivityService,
      );
    });

    test('submitReport stores hazard correctly', () async {
      final hazard = HazardDisplayModel(
        id: '',
        type: HazardType.landslide,
        description: 'Road blocked near Kakul',
        upvotes: 1,
        downvotes: 0,
        trustScore: 1.0,
        reporterName: 'UserA',
        reporterTier: ReputationTier.rookie,
        reportedAt: DateTime.now(),
        latitude: 34.15,
        longitude: 73.21,
        distanceMeters: 0.0,
        currentUserVote: VoteState.upvoted,
        isOwnReport: true,
        reporterId: 'user_a',
      );

      final docId = await hazardRepository.submitReport(hazard);
      expect(docId, isNotEmpty);
      expect(fakeHazardDataSource.hazardsDb[docId]?.description, 'Road blocked near Kakul');
    });

    test('vote on hazard registers upvotes and updates trustScore', () async {
      // Pre-populate hazard
      final initial = HazardDto(
        id: 'h_1',
        type: HazardType.flood,
        description: 'Flooding in Narian',
        upvotes: 1,
        downvotes: 0,
        trustScore: 1.0,
        reporterName: 'ReporterX',
        reporterTier: ReputationTier.rookie,
        reportedAt: DateTime.now(),
        latitude: 34.15,
        longitude: 73.21,
        geohash: 'abcde',
        reporterId: 'user_reporter',
      );
      fakeHazardDataSource.hazardsDb['h_1'] = initial;

      // Upvote by user_2
      await fakeHazardDataSource.voteOnHazard('h_1', 'user_2', true);
      
      final hazard = fakeHazardDataSource.hazardsDb['h_1']!;
      expect(hazard.upvotes, 2);
      expect(hazard.downvotes, 0);
      expect(hazard.trustScore, 1.0);

      // Downvote by user_3
      await fakeHazardDataSource.voteOnHazard('h_1', 'user_3', false);

      final hazardUpdated = fakeHazardDataSource.hazardsDb['h_1']!;
      expect(hazardUpdated.upvotes, 2);
      expect(hazardUpdated.downvotes, 1);
      expect(hazardUpdated.trustScore, closeTo(2 / 3, 0.01));
    });
  });

  group('WeatherRepository Tests', () {
    late FakeOpenMeteoWeatherDataSource fakeWeatherDataSource;
    late WeatherRepository weatherRepository;
    late FakeFirebasePerformance fakePerformance;

    setUp(() {
      fakeWeatherDataSource = FakeOpenMeteoWeatherDataSource();
      fakePerformance = FakeFirebasePerformance();
      weatherRepository = WeatherRepository(
        fakeWeatherDataSource,
        performance: fakePerformance,
      );
    });

    test('getCurrentWeather fetches and parses data successfully', () async {
      final weather = await weatherRepository.getCurrentWeather(34.15, 73.21);
      expect(weather.temperature, 24.5);
      expect(weather.humidity, 65);
      expect(weather.windSpeed, 12.4);
      expect(weather.condition, 'Partly Cloudy');
    });
  });
}
