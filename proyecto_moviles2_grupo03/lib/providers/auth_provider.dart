import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';

enum AuthStatus { unauthenticated, loading, authenticated, error, locked }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final TokenStorage _tokenStorage;
  final DateTime Function() _now;

  AuthStatus _status = AuthStatus.unauthenticated;
  String? _token;
  String? _errorMessage;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  static const int maxFailedAttempts = 3;
  static const Duration lockDuration = Duration(seconds: 60);

  AuthProvider(this._authService, this._tokenStorage, {DateTime Function()? now}) 
      : _now = now ?? (() => DateTime.now());

  AuthStatus get status => _status;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  int get failedAttempts => _failedAttempts;
  DateTime? get lockedUntil => _lockedUntil;

  Future<void> login(String email, String password) async {
    // Si ya hay un bloqueo activo, verificamos si expiró
    if (_status == AuthStatus.locked) {
      if (_now().isBefore(_lockedUntil!)) {
        // Aún bloqueado
        return;
      } else {
        // Bloqueo expirado, reiniciar
        _failedAttempts = 0;
        _lockedUntil = null;
        _status = AuthStatus.unauthenticated;
      }
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.signIn(email, password);
      // Login exitoso: reiniciar contador, guardar token
      _failedAttempts = 0;
      _lockedUntil = null;
      _token = token;
      await _tokenStorage.writeToken(token);
      _status = AuthStatus.authenticated;
      notifyListeners();
    } on AuthFailure catch (e) {
      _failedAttempts++;
      // Verificar condición de bloqueo
      if (_failedAttempts >= maxFailedAttempts) {
        _lockedUntil = _now().add(lockDuration);
        _status = AuthStatus.locked;
        final seconds = _lockedUntil!.difference(_now()).inSeconds;
        _errorMessage = 'Cuenta bloqueada por múltiples intentos fallidos. Intente en $seconds segundos.';
      } else {
        _status = AuthStatus.error;
        _errorMessage = e.message;
      }
      notifyListeners();
    } catch (e) {
      // Errores de red u otros no incrementan el contador
      _status = AuthStatus.error;
      _errorMessage = 'Error de conexión o problema inesperado.';
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    _token = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    _failedAttempts = 0;
    _lockedUntil = null;
    notifyListeners();
  }
}
