import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/fcm_notification_service.dart';
import '../../data/datasources/remote/firestore_user_datasource.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  StreamSubscription<bool>? _authSubscription;

  AuthProvider(this._authService) {
    _init();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => _authService.currentUserId;

  void _init() {
    _authSubscription = _authService.authStateChanges.listen((status) async {
      _isAuthenticated = status;
      _errorMessage = null;
      notifyListeners();

      if (status && _authService.currentUserId != null) {
        try {
          final fcm = FcmNotificationService();
          final token = await fcm.getToken();
          if (token != null) {
            await FirestoreUserDataSource().updateUserProfile(
              _authService.currentUserId!,
              {'fcmToken': token},
            );
          }
        } catch (_) {}
      }
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signIn(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _formatAuthError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _formatAuthError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String username) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signUp(email, password, username);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _formatAuthError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _formatAuthError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signOut();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _formatAuthError(dynamic error) {
    // Simple user-friendly parsing of Firebase Auth exceptions
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('user-not-found') ||
        errStr.contains('invalid-credential')) {
      return 'Invalid email or password.';
    } else if (errStr.contains('wrong-password')) {
      return 'Incorrect password.';
    } else if (errStr.contains('email-already-in-use')) {
      return 'This email is already registered.';
    } else if (errStr.contains('invalid-email')) {
      return 'The email address is badly formatted.';
    } else if (errStr.contains('weak-password')) {
      return 'The password must be at least 6 characters long.';
    } else if (errStr.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection.';
    }
    return error.toString().replaceAll(RegExp(r'\[.*\]'), '').trim();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
