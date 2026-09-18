import 'package:firebase_auth/firebase_auth.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<String> login(String correo, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: correo,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('No se pudo iniciar sesión');
    }

    return user.uid;
  }

  @override
  Future<String> registrar(String correo, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: correo,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('No se pudo registrar el usuario');
    }

    return user.uid;
  }
}