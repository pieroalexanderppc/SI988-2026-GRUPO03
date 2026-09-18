import 'auth_repository.dart';
import 'entrada_cleaner.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<String> ejecutar(
    String correo,
    String password,
  ) async {
    final correoLimpio = _validarEntrada(
      correo,
      password,
    );

    return repository.login(
      correoLimpio,
      password,
    );
  }

  Future<String> registrar(
    String correo,
    String password,
  ) async {
    final correoLimpio = _validarEntrada(
      correo,
      password,
    );

    return repository.registrar(
      correoLimpio,
      password,
    );
  }

  String _validarEntrada(
    String correo,
    String password,
  ) {
    final correoLimpio =
        EntradaCleaner.limpiar(correo);

    if (!_correoValido(correoLimpio)) {
      throw ArgumentError(
        'El correo no es válido',
      );
    }

    if (password.length < 6) {
      throw ArgumentError(
        'La contraseña debe tener mínimo 6 caracteres',
      );
    }

    return correoLimpio;
  }

  bool _correoValido(String correo) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(correo);
  }
}
