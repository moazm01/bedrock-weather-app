import 'package:cloud_firestore/cloud_firestore.dart';
import '../../dto/user_dto.dart';
import '../../../domain/enums/domain_enums.dart';

class FirestoreUserDataSource {
  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _usersCollection =>
      _firestore?.collection('users');

  Future<UserDto?> getUserProfile(String uid) async {
    final coll = _usersCollection;
    if (coll == null) return null;
    try {
      final doc = await coll.doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserDto.fromFirestore(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }

  Future<void> createUserProfile(
    String uid,
    String email,
    String username,
  ) async {
    final coll = _usersCollection;
    if (coll == null) return;
    final initialData = UserDto(
      uid: uid,
      username: username,
      email: email,
      tier: ReputationTier.rookie,
      totalReports: 0,
      verificationRate: 0.0,
      trustCoefficient: 0.0,
    );
    try {
      await coll.doc(uid).set(initialData.toFirestore());
    } catch (_) {}
  }

  Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> fields,
  ) async {
    final coll = _usersCollection;
    if (coll == null) return;
    try {
      await coll.doc(uid).update(fields);
    } catch (_) {}
  }

  Stream<UserDto?> streamUserProfile(String uid) {
    final coll = _usersCollection;
    if (coll == null) return Stream.value(null);
    try {
      return coll.doc(uid).snapshots().map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        return UserDto.fromFirestore(doc.data()!, doc.id);
      });
    } catch (_) {
      return Stream.value(null);
    }
  }
}
