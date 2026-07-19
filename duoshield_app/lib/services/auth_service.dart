import 'package:firebase_auth/firebase_auth.dart';
import '../network/push_server.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<String?> getIdToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  static Future<UserCredential> signInWithCustomToken(String token) async {
    return await _auth.signInWithCustomToken(token);
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
