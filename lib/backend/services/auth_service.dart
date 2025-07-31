import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Necesario para Firestore
import '../model/emprendimiento_model.dart'; 

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

  /// Obtener un emprendimiento por ID
  Future<EmprendimientoModel?> obtenerEmprendimientoPorId(String id) async {
    final doc = await FirebaseFirestore.instance
        .collection('emprendimientos')
        .doc(id)
        .get();

    if (doc.exists) {
      return EmprendimientoModel.fromJson(doc.data()!, doc.id);
    }
    return null;
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
