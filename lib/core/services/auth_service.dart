// Clean Architecture: Authentication service
abstract class AuthService {
  // TODO: Implement with Firebase Auth or custom JWT backend

  Future<void> signIn(String email, String password);
  Future<void> signUp(String email, String password, String username);
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<void> resetPassword(String email);

  Stream<bool> get authStateChanges;
  String? get currentUserId;
}
