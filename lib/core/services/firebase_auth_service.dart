import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/datasources/remote/firestore_user_datasource.dart';
import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> signIn(String email, String password) async {
    final auth = _auth;
    if (auth == null) {
      throw Exception(
        'Firebase is not yet configured. Please follow the instructions to connect your project.',
      );
    }
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signUp(String email, String password, String username) async {
    final auth = _auth;
    if (auth == null) {
      throw Exception(
        'Firebase is not yet configured. Please follow the instructions to connect your project.',
      );
    }
    // 1. Create user in Firebase Auth
    final userCredential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // 2. Set the display name in Firebase Auth and initialize profile doc in Firestore
    final user = userCredential.user;
    if (user != null) {
      await user.updateDisplayName(username.trim());

      try {
        await FirestoreUserDataSource().createUserProfile(
          user.uid,
          email.trim(),
          username.trim(),
        );
      } catch (_) {
        // Suppress writing errors if Firestore is not yet configured
      }
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null) {
      throw Exception(
        'Firebase is not yet configured. Please follow the instructions to connect your project.',
      );
    }

    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      final docId = user.uid;
      try {
        final doc = await FirestoreUserDataSource().getUserProfile(docId);
        if (doc == null) {
          await FirestoreUserDataSource().createUserProfile(
            docId,
            user.email ?? '',
            user.displayName ?? 'Google User',
          );
        }
      } catch (_) {}
    }
  }

  @override
  Future<void> signOut() async {
    await _auth?.signOut();
  }

  @override
  Future<void> resetPassword(String email) async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase is not yet configured.');
    }
    await auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Stream<bool> get authStateChanges {
    final auth = _auth;
    if (auth == null) {
      return Stream.value(false);
    }
    return auth.authStateChanges().map((user) => user != null);
  }

  @override
  String? get currentUserId => _auth?.currentUser?.uid;

  User? get currentUser => _auth?.currentUser;
}
