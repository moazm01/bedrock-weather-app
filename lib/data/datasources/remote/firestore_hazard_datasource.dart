import 'package:cloud_firestore/cloud_firestore.dart';
import '../../dto/hazard_dto.dart';
import '../../../core/utils/geohash_util.dart';

class FirestoreHazardDataSource {
  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _hazardsCollection =>
      _firestore?.collection('hazards');

  /// Submits a new hazard report. Increments user's totalReports atomically. Returns the doc ID.
  Future<String> submitHazard(HazardDto hazard, String userId) async {
    final firestore = _firestore;
    final coll = _hazardsCollection;
    if (firestore == null || coll == null) {
      throw Exception('Firebase is not configured. Cannot submit hazard.');
    }

    final batch = firestore.batch();

    // Create hazard doc
    final docRef = coll.doc();
    final data = hazard.toFirestore();
    data['reporterId'] = userId;
    data['status'] = 'active';
    // Auto-expire in 6 hours
    data['expiresAt'] = Timestamp.fromDate(
      hazard.reportedAt.add(const Duration(hours: 6)),
    );

    batch.set(docRef, data);

    // Increment totalReports in user document
    final userRef = firestore.collection('users').doc(userId);
    batch.update(userRef, {'totalReports': FieldValue.increment(1)});

    await batch.commit();
    return docRef.id;
  }

  /// Streams active, unexpired hazards in real-time.
  Stream<List<HazardDto>> streamLiveHazards() {
    final coll = _hazardsCollection;
    if (coll == null) return Stream.value([]);

    try {
      final now = DateTime.now();
      return coll
          .where('status', isEqualTo: 'active')
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => HazardDto.fromFirestore(doc.data(), doc.id))
                .toList();
          });
    } catch (_) {
      return Stream.value([]);
    }
  }

  /// Retrieves hazards in a given location using geohash queries.
  Future<List<HazardDto>> getNearbyHazards(
    double lat,
    double lng,
    double radiusKm,
  ) async {
    final coll = _hazardsCollection;
    if (coll == null) return [];

    try {
      final prefix = GeohashUtil.getQueryPrefix(lat, lng, radiusKm);

      // Geohash prefix range query
      final query = await coll
          .where('status', isEqualTo: 'active')
          .orderBy('geohash')
          .startAt([prefix])
          .endAt(['$prefix\uf8ff'])
          .get();

      return query.docs
          .map((doc) => HazardDto.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Atomically casts or toggles a vote on a hazard, updating counters.
  Future<void> voteOnHazard(
    String hazardId,
    String userId,
    bool isUpvote,
  ) async {
    final firestore = _firestore;
    final coll = _hazardsCollection;
    if (firestore == null || coll == null) {
      throw Exception('Firebase is not configured. Cannot vote.');
    }

    final hazardRef = coll.doc(hazardId);
    final voteRef = hazardRef.collection('votes').doc(userId);

    try {
      await firestore.runTransaction((transaction) async {
        final hazardSnapshot = await transaction.get(hazardRef);
        final voteSnapshot = await transaction.get(voteRef);

        if (!hazardSnapshot.exists) {
          throw Exception('Hazard report does not exist.');
        }

        final hazardData = hazardSnapshot.data()!;
        int upvotes = hazardData['upvotes'] as int? ?? 0;
        int downvotes = hazardData['downvotes'] as int? ?? 0;

        String? existingVote;
        if (voteSnapshot.exists) {
          existingVote = voteSnapshot.data()?['vote'] as String?;
        }

        String targetVote = isUpvote ? 'up' : 'down';

        if (existingVote == targetVote) {
          // Toggle off the vote
          if (isUpvote) {
            upvotes = (upvotes - 1).clamp(0, 99999);
          } else {
            downvotes = (downvotes - 1).clamp(0, 99999);
          }
          transaction.delete(voteRef);
        } else {
          // Changing vote or voting for the first time
          if (existingVote == 'up') {
            upvotes = (upvotes - 1).clamp(0, 99999);
          } else if (existingVote == 'down') {
            downvotes = (downvotes - 1).clamp(0, 99999);
          }

          if (isUpvote) {
            upvotes++;
          } else {
            downvotes++;
          }
          transaction.set(voteRef, {
            'vote': targetVote,
            'votedAt': FieldValue.serverTimestamp(),
          });
        }

        // Compute simple trust score: upvotes / (upvotes + downvotes)
        double trustScore = 0.0;
        if (upvotes + downvotes > 0) {
          trustScore = upvotes / (upvotes + downvotes);
        }

        transaction.update(hazardRef, {
          'upvotes': upvotes,
          'downvotes': downvotes,
          'trustScore': trustScore,
        });
      });
    } catch (_) {}
  }

  /// Fetches a specific user's vote for a hazard.
  Future<String?> getUserVote(String hazardId, String userId) async {
    final coll = _hazardsCollection;
    if (coll == null) return null;
    try {
      final doc = await coll
          .doc(hazardId)
          .collection('votes')
          .doc(userId)
          .get();
      if (!doc.exists) return null;
      return doc.data()?['vote'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Batch fetches all votes for a user across all hazards using collection group query.
  Future<Map<String, String>> getUserVotes(String userId) async {
    final fs = _firestore;
    if (fs == null) return {};
    try {
      final snapshot = await fs
          .collectionGroup('votes')
          .where(FieldPath.documentId, isEqualTo: userId)
          .get();
      final Map<String, String> votesMap = {};
      for (var doc in snapshot.docs) {
        final hazardId = doc.reference.parent.parent?.id;
        if (hazardId != null) {
          votesMap[hazardId] = doc.data()['vote'] as String? ?? 'none';
        }
      }
      return votesMap;
    } catch (_) {
      return {};
    }
  }

  /// Admin action: Mark a hazard report as resolved.
  Future<void> resolveHazard(String hazardId, String resolvedById) async {
    final coll = _hazardsCollection;
    if (coll == null) return;
    try {
      await coll.doc(hazardId).update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedById': resolvedById,
      });
    } catch (_) {}
  }

  /// Update the image URL of a hazard report.
  Future<void> updateHazardImage(String hazardId, String imageUrl) async {
    final coll = _hazardsCollection;
    if (coll == null) return;
    try {
      await coll.doc(hazardId).update({
        'imageUrl': imageUrl,
      });
    } catch (_) {}
  }
}
