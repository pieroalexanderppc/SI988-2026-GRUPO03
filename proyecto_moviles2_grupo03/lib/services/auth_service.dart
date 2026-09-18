import 'package:firebase_auth/firebase_auth.dart' as firebase;

class AuthFailure implements Exception {
  final String message;
  AuthFailure(this.message);

  @override
  String toString() => message;
}

abstract class AuthService {
  Future<String> signIn(String email, String password);
}

class FirebaseAuthService implements AuthService {
  final firebase.FirebaseAuth _firebaseAuth = firebase.FirebaseAuth.instance;

  @override
  Future<String> signIn(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final token = await credential.user?.getIdToken();
      if (token == null) {
        throw AuthFailure('No se pudo obtener el token de sesión.');
      }
      return token;
    } on firebase.FirebaseAuthException catch (e) {
      throw AuthFailure(e.message ?? 'Error de autenticación.');
    } catch (e) {
      throw AuthFailure('Ocurrió un error inesperado.');
    }
  }
}
