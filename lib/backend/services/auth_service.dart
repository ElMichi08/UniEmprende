import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    if (!email.endsWith('@espe.edu.ec')) {
      throw FirebaseAuthException(
        code: 'invalid-domain',
        message: 'Solo se permiten correos @espe.edu.ec',
      );
    }

    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> registerWithEmail(String email, String password) async {
    if (!email.endsWith('@espe.edu.ec')) {
      throw FirebaseAuthException(
        code: 'invalid-domain',
        message: 'Solo se permiten correos @espe.edu.ec',
      );
    }

    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    return await _auth.signOut();
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
