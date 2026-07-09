import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  FirebaseStorage? get _storage {
    try {
      return FirebaseStorage.instance;
    } catch (_) {
      return null;
    }
  }

  Future<String?> uploadHazardPhoto(String localPath, String hazardId) async {
    final storage = _storage;
    if (storage == null) return null;
    try {
      final ref = storage
          .ref()
          .child('hazards')
          .child(hazardId)
          .child('evidence.jpg');
      final uploadTask = await ref.putFile(File(localPath));
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (_) {
      return null;
    }
  }

  Future<String?> uploadUserAvatar(String localPath, String uid) async {
    final storage = _storage;
    if (storage == null) return null;
    try {
      final ref = storage.ref().child('avatars').child(uid).child('avatar.jpg');
      final uploadTask = await ref.putFile(File(localPath));
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (_) {
      return null;
    }
  }
}
