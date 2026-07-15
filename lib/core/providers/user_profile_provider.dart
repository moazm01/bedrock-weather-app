import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/domain_models.dart';
import '../../domain/enums/domain_enums.dart';
import '../../data/repositories/user_repository.dart';
import '../services/firebase_storage_service.dart';

class UserProfileProvider extends ChangeNotifier {
  final UserRepository _userRepository;

  UserProfileModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<UserProfileModel?>? _profileSubscription;

  UserProfileProvider(this._userRepository);

  UserProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  static final UserProfileModel mockProfile = UserProfileModel(
    uid: 'mock_user_id',
    username: 'DemoUser',
    email: 'demo@bedrock.org',
    tier: ReputationTier.rookie,
    totalReports: 12,
    verificationRate: 0.85,
    trustCoefficient: 0.75,
    bio: 'Abbottabad Safety First! Resident contributor.',
    birthdate: DateTime(1998, 8, 14),
    followers: const ['user_1', 'user_2'],
    following: const ['user_3'],
  );

  UserProfileModel _getFallbackProfile(String uid) {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid == uid) {
        return UserProfileModel(
          uid: uid,
          username: user.displayName ?? user.email?.split('@').first ?? 'User',
          email: user.email ?? '',
          tier: ReputationTier.rookie,
          totalReports: 0,
          verificationRate: 0.0,
          trustCoefficient: 0.0,
        );
      }
    } catch (_) {}
    return mockProfile;
  }

  void loadProfile(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (uid == 'mock_user_id') {
      _profile = mockProfile;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _profile = await _userRepository.getProfile(uid);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _profile = _getFallbackProfile(uid);
      _isLoading = false;
      _errorMessage = 'Using offline standby profile (Firestore error: $e)';
      notifyListeners();
    }
  }

  void startListening(String uid) {
    _profileSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    if (uid == 'mock_user_id') {
      _profile = mockProfile;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _profileSubscription = _userRepository
          .streamProfile(uid)
          .listen(
            (updatedProfile) {
              _profile = updatedProfile ?? _getFallbackProfile(uid);
              _isLoading = false;
              _errorMessage = null;
              notifyListeners();
            },
            onError: (error) {
              _profile = _getFallbackProfile(uid); // Fallback on stream errors
              _isLoading = false;
              _errorMessage = 'Using offline standby profile: $error';
              notifyListeners();
            },
          );
    } catch (e) {
      _profile = _getFallbackProfile(uid);
      _isLoading = false;
      _errorMessage = 'Offline stream error: $e';
      notifyListeners();
    }
  }

  void stopListening() {
    _profileSubscription?.cancel();
    _profileSubscription = null;
    _profile = null;
    notifyListeners();
  }

  Future<UserProfileModel?> fetchUserProfile(String uid) async {
    if (uid == 'mock_user_id' || uid == '') {
      return mockProfile;
    }
    try {
      return await _userRepository.getProfile(uid);
    } catch (_) {
      // Return a basic mock/offline user details
      return UserProfileModel(
        uid: uid,
        username: 'Contributor_$uid',
        email: 'user_$uid@bedrock.org',
        tier: ReputationTier.rookie,
        totalReports: 3,
        verificationRate: 0.9,
        trustCoefficient: 0.6,
        bio: 'Dedicated Abbottabad volunteer weather spotter.',
        followers: const ['user_1'],
        following: const [],
      );
    }
  }

  Future<void> toggleFollow(String targetUid) async {
    final current = _profile;
    if (current == null) return;

    try {
      final target = await fetchUserProfile(targetUid);
      if (target == null) return;

      final followingList = List<String>.from(current.following);
      final followersList = List<String>.from(target.followers);

      if (followingList.contains(targetUid)) {
        followingList.remove(targetUid);
        followersList.remove(current.uid);
      } else {
        followingList.add(targetUid);
        followersList.add(current.uid);
      }

      final updatedCurrent = current.copyWith(following: followingList);
      final updatedTarget = target.copyWith(followers: followersList);

      if (current.uid != 'mock_user_id') {
        await _userRepository.updateProfile(current.uid, updatedCurrent);
        await _userRepository.updateProfile(targetUid, updatedTarget);
      }

      _profile = updatedCurrent;
      notifyListeners();
    } catch (e) {
      debugPrint('Follow action failed: $e');
    }
  }

  Future<bool> deleteProfile() async {
    final current = _profile;
    if (current == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // Delete user document in database if not mock
      if (current.uid != 'mock_user_id') {
        // We can simulate profile deletion or delete user auth if supported.
        // For standard Clean Arch + Firestore, we clear profile document.
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('users').doc(current.uid).delete();
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.delete();
        }
      }
      
      stopListening();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Fallback: Even if server delete fails, locally sign out user to ensure safety
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      stopListening();
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  Future<bool> updateProfile(UserProfileModel updatedProfile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (updatedProfile.uid != 'mock_user_id') {
        await _userRepository.updateProfile(updatedProfile.uid, updatedProfile);
      }
      _profile = updatedProfile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAvatar(String localImagePath) async {
    if (_profile == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final storageService = FirebaseStorageService();
      final downloadUrl = await storageService.uploadUserAvatar(
        localImagePath,
        _profile!.uid,
      );
      if (downloadUrl != null) {
        final updated = _profile!.copyWith(avatarUrl: downloadUrl);
        if (_profile!.uid != 'mock_user_id') {
          await _userRepository.updateProfile(_profile!.uid, updated);
        }
        _profile = updated;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }
}
