import 'package:flutter_test/flutter_test.dart';

import '../lib/services/auth_repository.dart';
import '../lib/services/entrada_cleaner.dart';
import '../lib/services/login_use_case.dart';

class FakeAuthRepository implements AuthRepository {
  int loginInvocaciones = 0;
  int registrarInvocaciones = 0;

  bool sesionActiva = false;
  String? entidadCargada;

  bool rechazarLogin = false;

  @override
  Future<String> login(String correo, String password) async {
    loginInvocaciones++;

    if (rechazarLogin) {
      throw Exception('Credenciales rechazadas');
    }

    sesionActiva = true;
    entidadCargada = 'Usuario: $correo';

    return entidadCargada!;
  }

  @override
  Future<String> registrar(String correo, String password) async {
    registrarInvocaciones++;

    sesionActiva = true;
    entidadCargada = 'Usuario: $correo';

    return entidadCargada!;
  }
}

void main() {
  group('Punto 4 - Pruebas de login y carga', () {
    test('4a - Al arrancar no hay sesión', () {
      final repository = FakeAuthRepository();

      expect(repository.sesionActiva, false);

      print(
        '4a - Sesión al arrancar: ${repository.sesionActiva}',
      );
    });

    test('4b - Login correcto y entidad cargada', () async {
      final repository = FakeAuthRepository();
      final useCase = LoginUseCase(repository);

      final resultado = await useCase.ejecutar(
        'usuario@gmail.com',
        '123456',
      );

      expect(repository.loginInvocaciones, 1);
      expect(repository.sesionActiva, true);
      expect(repository.entidadCargada, isNotNull);
      expect(resultado, 'Usuario: usuario@gmail.com');

      print('4b - Login correcto');
      print(
        'Entidad cargada: ${repository.entidadCargada}',
      );
      print(
        'Invocaciones al repositorio: '
        '${repository.loginInvocaciones}',
      );
    });

    test('4c - Login rechazado sin segundo intento', () async {
      final repository = FakeAuthRepository();
      repository.rechazarLogin = true;

      final useCase = LoginUseCase(repository);

      try {
        await useCase.ejecutar(
          'usuario@gmail.com',
          '123456',
        );
      } catch (e) {
        print('4c - Login rechazado: $e');
      }

      expect(repository.loginInvocaciones, 1);

      print(
        'Invocaciones al repositorio: '
        '${repository.loginInvocaciones}',
      );
    });
  });

  group('Punto 5 - Limpieza y rechazo antes del repositorio', () {
    test('5a - Limpieza de espacios y tabuladores', () {
      const entrada = '  juan\t  perez \n';

      final resultado = EntradaCleaner.limpiar(entrada);

      expect(resultado, 'juan perez');

      print(
        '5a - Entrada original: "$entrada"',
      );
      print(
        '5a - Entrada limpia: "$resultado"',
      );
    });

    test('5b - Entrada inválida no llama al repositorio', () async {
      final repository = FakeAuthRepository();
      final useCase = LoginUseCase(repository);

      try {
        await useCase.ejecutar(
          'correo-invalido',
          '123456',
        );
      } catch (e) {
        print('5b - Entrada rechazada: $e');
      }

      expect(repository.loginInvocaciones, 0);

      print(
        '5b - Invocaciones al repositorio: '
        '${repository.loginInvocaciones}',
      );
    });
  });
}