import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  static final UserProfileModel mockProfile = const UserProfileModel(
    uid: 'mock_user_id',
    username: 'DemoUser',
    email: 'demo@bedrock.org',
    tier: ReputationTier.rookie,
    totalReports: 12,
    verificationRate: 0.85,
    trustCoefficient: 0.75,
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

  Future<bool> updateProfile(UserProfileModel updatedProfile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _userRepository.updateProfile(updatedProfile.uid, updatedProfile);
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
        final updated = UserProfileModel(
          uid: _profile!.uid,
          username: _profile!.username,
          email: _profile!.email,
          tier: _profile!.tier,
          totalReports: _profile!.totalReports,
          verificationRate: _profile!.verificationRate,
          trustCoefficient: _profile!.trustCoefficient,
          avatarUrl: downloadUrl,
        );
        await _userRepository.updateProfile(_profile!.uid, updated);
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
