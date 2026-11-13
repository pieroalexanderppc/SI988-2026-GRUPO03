import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get usuarioActual => _auth.currentUser;

  Future<void> cambiarPassword({
    required String passwordActual,
    required String passwordNueva,
  }) async {
    final user = _auth.currentUser;

    if (user == null || user.email == null) {
      throw Exception('No hay una sesión activa.');
    }

    final credencial = EmailAuthProvider.credential(
      email: user.email!,
      password: passwordActual,
    );

    await user.reauthenticateWithCredential(credencial);
    await user.updatePassword(passwordNueva);
  }
}