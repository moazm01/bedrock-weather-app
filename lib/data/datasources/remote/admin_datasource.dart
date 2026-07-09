import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDataSource {
  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<int> getActiveUsersCount() async {
    final fs = _firestore;
    if (fs == null) return 0;
    try {
      final snapshot = await fs.collection('users').get();
      return snapshot.docs.length;
    } catch (_) {
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
    } catch (_) {
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
    } catch (_) {
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
    } catch (_) {}
  }

  Future<void> sendSystemBroadcast(String title, String body) async {
    final fs = _firestore;
    if (fs == null) return;
    try {
      // Write system advisory broadcast alert doc
      await fs.collection('system_broadcasts').add({
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // Extended Admin Functions

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final fs = _firestore;
    if (fs == null) return _getMockUsers();
    try {
      final snapshot = await fs.collection('users').get();
      if (snapshot.docs.isEmpty) return _getMockUsers();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
    } catch (_) {
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
    } catch (_) {}
  }

  Future<void> toggleUserBan(String uid, bool isBanned) async {
    final fs = _firestore;
    if (fs == null) return;
    try {
      await fs.collection('users').doc(uid).update({'isBanned': isBanned});
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getAllHazards() async {
    final fs = _firestore;
    if (fs == null) return _getMockHazards();
    try {
      final snapshot = await fs.collection('hazards').get();
      if (snapshot.docs.isEmpty) return _getMockHazards();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (_) {
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
    } catch (_) {}
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
    } catch (_) {}
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
    } catch (_) {}
  }
}
