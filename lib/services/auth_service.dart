import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── Current user ──────────────────────────────────────────────────────────
  static User? get currentUser => _auth.currentUser;
  static String? get userId    => _auth.currentUser?.uid;
  static bool   get isLoggedIn => _auth.currentUser != null;

  // ── Auth state stream (listen for login/logout changes) ───────────────────
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Google Sign In ────────────────────────────────────────────────────────
  static Future<User?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled

      // Get auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential result =
          await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      return null;
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
