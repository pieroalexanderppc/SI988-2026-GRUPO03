import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Excepción personalizada cuando el correo no pertenece al dominio institucional
/// o a la lista de administradores/pruebas autorizados.
class CorreoNoAutorizadoException implements Exception {
  final String email;
  final String mensaje;

  CorreoNoAutorizadoException({
    required this.email,
    this.mensaje =
        'Acceso restringido: Debes usar tu correo institucional (@virtual.upt.pe) para ingresar a Pondera.',
  });

  @override
  String toString() => mensaje;
}

/// Servicio de autenticación que encapsula Firebase Auth y Google Sign-In (H29).
class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']),
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Dominios institucionales autorizados de la Universidad Privada de Tacna.
  static const List<String> dominiosInstitucionales = [
    '@virtual.upt.pe',
    '@upt.pe',
  ];

  /// Correos individuales en lista blanca (cuenta de administración / testing).
  static const List<String> correosAdminAutorizados = [
    'elvismv.2016@gmail.com',
  ];

  /// Valida si un correo electrónico está autorizado para acceder.
  static bool esCorreoAutorizado(String? email) {
    if (email == null) return false;
    final lower = email.trim().toLowerCase();
    if (correosAdminAutorizados.contains(lower)) return true;
    return dominiosInstitucionales.any((dominio) => lower.endsWith(dominio));
  }

  /// Retorna el usuario actual de Firebase.
  User? get usuarioActual => _auth.currentUser;

  /// Stream reactivo de cambios de sesión.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Inicia sesión con Google mediante OAuth 2.0 y OpenID Connect (H29).
  ///
  /// Valida el dominio institucional antes de completar el inicio de sesión.
  /// Si el correo no es institucional ni admin, revoca la sesión y lanza [CorreoNoAutorizadoException].
  Future<UserCredential?> iniciarSesionConGoogle() async {
    // 1. Desplegar selector nativo de Google Sign-In
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // El usuario canceló la selección de cuenta
      return null;
    }

    final email = googleUser.email;

    // 2. Validar dominio institucional o cuenta admin
    if (!esCorreoAutorizado(email)) {
      // Desconectar cuenta de Google no autorizada
      await _googleSignIn.signOut();
      throw CorreoNoAutorizadoException(email: email);
    }

    // 3. Obtener tokens de autenticación de Google
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // 4. Crear credencial de Firebase
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 5. Autenticar en Firebase con la credencial
    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    final User? user = userCredential.user;

    // 6. Sincronizar o crear documento de usuario en Firestore
    if (user != null) {
      await _sincronizarPerfilUsuario(user, googleUser);
    }

    return userCredential;
  }

  /// Sincroniza los datos del usuario en Firestore (`usuarios/{uid}`).
  Future<void> _sincronizarPerfilUsuario(User user, GoogleSignInAccount googleUser) async {
    try {
      final userDoc = _firestore.collection('usuarios').doc(user.uid);
      await userDoc.set({
        'uid': user.uid,
        'email': user.email ?? googleUser.email,
        'displayName': user.displayName ?? googleUser.displayName ?? '',
        'photoURL': user.photoURL ?? googleUser.photoUrl,
        'proveedor': 'google.com',
        'emailVerified': true,
        'ultimoAcceso': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // No bloquear el inicio de sesión si la escritura falla offline
    }
  }

  /// Cierra la sesión en Firebase y desconecta Google Sign-In.
  Future<void> cerrarSesion() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
