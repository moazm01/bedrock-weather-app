import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/logger_service.dart';

class AdminDataSource {
  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (e, stack) {
      LoggerService.logError(e, stack, context: 'AdminDataSource._firestore');
      return null;
    }
  }

  Future<int> getActiveUsersCount() async {
    final fs = _firestore;
    if (fs == null) return 0;
    try {
      final snapshot = await fs.collection('users').get();
      return snapshot.docs.length;
    } catch (e, stack) {
      LoggerService.logError(e, stack, context: 'AdminDataSource.getActiveUsersCount');
      return 0;
    }
  }

  Future<int> getLiveHazardsCount() async {
    final fs = _firestore;
    if (fs == null) return 0;
    try {
      final snapshot = await fs
          .collection('hazards')
          .where('status', isEqualTo: 'active')
          .get();
      return snapshot.docs.length;
    } catch (e, stack) {
      LoggerService.logError(e, stack, context: 'AdminDataSource.getLiveHazardsCount');
      return 0;
    }
  }

  Future<int> getReportsTodayCount() async {
    final fs = _firestore;
    if (fs == null) return 0;
    try {
      final todayStart = DateTime.now().subtract(const Duration(hours: 24));
      final snapshot = await fs
          .collection('hazards')
          .where('reportedAt', isGreaterThan: Timestamp.fromDate(todayStart))
          .get();
      return snapshot.docs.length;
    } catch (e, stack) {
      LoggerService.logError(e, stack, context: 'AdminDataSource.getReportsTodayCount');
      return 0;
    }
  }

  Future<void> purgeAllReports() async {
    final fs = _firestore;
    if (fs == null) return;
    try {
      final query = await fs.collection('hazards').get();
      final batch = fs.batch();
      for (var doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e, stack) {
      LoggerService.logError(e, stack, context: 'AdminDataSource.purgeAllReports');
    }
  }

  Future<void> sendSystemBroadcast(String title, String body) async {
    final fs = _firestore;
    if (fs == null) return;
    try {
      await fs.collection('system_broadcasts').add({
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      LoggerService.logError(e, stack, context: 'AdminDataSource.sendSystemBroadcast');
    }
  }

  // Extended Admin Functions

  Future<List<Map<String, dynamic>>> getAllUsers({int limit = 50, DocumentSnapshot? startAfter}) async {
    final fs = _firestore;
    if (fs == null) return _getMockUsers();
    try {
      var query = fs.collection('users').orderBy('username');
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      final snapshot = await query.limit(limit).get();
      if (snapshot.docs.isEmpty) return _getMockUsers();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        data['snapshot'] = doc;
        return data;
      }).toList();
    } catch (e, stack) {
      LoggerService.logError(e, stack, context: 'AdminDataSource.getAllUsers');
      return _getMockUsers();
    }
  }

  List<Map<String, dynamic>> _getMockUsers() {
    return [
      {
        'uid': 'mock_user_1',
        'username': 'Khurram Shehzad',
        'email': 'khurram@abbottabad.org',
        'tier': 'veteran',
        'totalReports': 24,
        'verificationRate': 0.92,
        'trustCoefficient': 0.88,
        'isBanned': false,
      },
      {
        'uid': 'mock_user_2',
        'username': 'Dr. Ayesha Malik',
        'email': 'ayesha.m@hospital.kp.gov',
        'tier': 'expert',
        'totalReports': 41,
        'verificationRate': 0.96,
        'trustCoefficient': 0.95,
        'isBanned': false,
      },
      {
        'uid': 'mock_user_3',
        'username': 'Zainab Qazi',
        'email': 'zainab.q@gmail.com',
        'tier': 'helper',
        'totalReports': 8,
        'verificationRate': 0.88,
        'trustCoefficient': 0.78,
        'isBanned': false,
      },
      {
        'uid': 'mock_user_4',
        'username': 'DemoUser',
        'email': 'demo@bedrock.org',
        'tier': 'rookie',
        'totalReports': 12,
        'verificationRate': 0.85,
        'trustCoefficient': 0.75,
        'isBanned': false,
      },
    ];
  }

  Future<void> updateUserTier(String uid, String tier) async {
    final fs = _firestore;
    if (fs == null) return;
    try {
      await fs.collection('users').doc(uid).update({'tier': tier});
    } catch (e, stack) {
      LoggerService.logError(e, stack, context: 'AdminDataSource.updateUserTier');
    }
  }

  Future<void> toggleUserBan(String uid, bool isBanned) async {
    final fs = _firestore;
    if (fs == null) return;
    try {
      await fs.collection('users').doc(uid).update({'isBanned': isBanned});
    } catch (e, stack) {
      LoggerService.logError(e, stack, context: 'AdminDataSource.toggleUserBan');
    }
  }

  Future<List<Map<String, dynamic>>> getAllHazards({int limit = 50, DocumentSnapshot? startAfter}) async {
    final fs = _firestore;
    if (fs == null) return _getMockHazards();
    try {
      var query = fs.collection('hazards').orderBy('reportedAt', descending: true);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      final snapshot = await query.limit(limit).get();
      if (snapshot.docs.isEmpty) return _getMockHazards();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['snapshot'] = doc;
        return data;
      }).toList();
    } catch (e, stack) {
      LoggerService.logError(e, stack, context: 'AdminDataSource.getAllHazards');
      return _getMockHazards();
    }
  }

  List<Map<String, dynamic>> _getMockHazards() {
    return [
      {
        'id': 'mock_hazard_1',
        'type': 'landslide',
        'description':
            'Landslide blocked PMA Road near Kakul. Main access restricted.',
        'upvotes': 8,
        'downvotes': 1,
        'trustScore': 0.88,
        'reporterName': 'Khurram Shehzad',
        'reporterTier': 'veteran',
        'reportedAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 1)),
        ),
        'latitude': 34.1958,
        'longitude': 73.2594,
        'status': 'active',
      },
      {
        'id': 'mock_hazard_2',
        'type': 'flood',
        'description':
            'Severe monsoon flooding on Karakoram Highway near Ayub Medical College.',
        'upvotes': 15,
        'downvotes': 2,
        'trustScore': 0.88,
        'reporterName': 'Dr. Ayesha Malik',
        'reporterTier': 'expert',
        'reportedAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 2)),
        ),
        'latitude': 34.1758,
        'longitude': 73.2294,
        'status': 'active',
      },
      {
        'id': 'mock_hazard_3',
        'type': 'fog',
        'description':
            'Zero visibility fog early morning at Shimla Hill viewpoint. Caution advised.',
        'upvotes': 4,
        'downvotes': 0,
        'trustScore': 1.0,
        'reporterName': 'Zainab Qazi',
        'reporterTier': 'helper',
        'reportedAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(minutes: 45)),
        ),
        'latitude': 34.1558,
        'longitude': 73.1994,
        'status': 'active',
      },
    ];
  }

  Future<void> deleteHazard(String hazardId) async {
    final fs = _firestore;
    if (fs == null) return;
    try {
      await fs.collection('hazards').doc(hazardId).delete();
    } catch (e, stack) {
      LoggerService.logError(e, stack, context: 'AdminDataSource.deleteHazard');
    }
  }

  Future<void> updateHazardVotes(
    String hazardId,
    int upvotes,
    int downvotes,
  ) async {
    final fs = _firestore;
    if (fs == null) return;
    try {
      double trustScore = 0.0;
      if (upvotes + downvotes > 0) {
        trustScore = upvotes / (upvotes + downvotes);
      }
      await fs.collection('hazards').doc(hazardId).update({
        'upvotes': upvotes,
        'downvotes': downvotes,
        'trustScore': trustScore,
      });
    } catch (e, stack) {
      LoggerService.logError(e, stack, context: 'AdminDataSource.updateHazardVotes');
    }
  }

  Future<void> resolveHazard(String hazardId, String resolvedById) async {
    final fs = _firestore;
    if (fs == null) return;
    try {
      await fs.collection('hazards').doc(hazardId).update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedById': resolvedById,
      });
    } catch (e, stack) {
      LoggerService.logError(e, stack, context: 'AdminDataSource.resolveHazard');
    }
  }
}
