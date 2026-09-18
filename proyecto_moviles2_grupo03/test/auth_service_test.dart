import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proyecto_moviles2_grupo03/models/usuario_model.dart';
import 'package:proyecto_moviles2_grupo03/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Punto 1 - Persistencia Local y Auto-Login (AuthService)', () {
    test('Inicialmente estaAutenticado retorna false si no hay token persistido', () async {
      final authService = AuthService();
      final estaAutenticado = await authService.estaAutenticado();
      expect(estaAutenticado, isFalse);

      final token = await authService.obtenerToken();
      expect(token, isNull);
    });

    test('Al guardar sesión se persiste el token e información del usuario en SharedPreferences', () async {
      final authService = AuthService();
      const usuario = UsuarioModel(
        id: '2020068763',
        nombre: 'Elvis Mamani Valdivia',
        email: 'elvmamani@upt.pe',
        codigo: '2020068763',
        token: 'token_prueba_persistencia_12345',
        saldoCentimos: 15000,
      );

      final guardadoExitoso = await authService.guardarSesion(
        usuario: usuario,
        token: 'token_prueba_persistencia_12345',
      );

      expect(guardadoExitoso, isTrue);

      // Verificar que el auto-login responderá true
      final estaAutenticado = await authService.estaAutenticado();
      expect(estaAutenticado, isTrue);

      final token = await authService.obtenerToken();
      expect(token, equals('token_prueba_persistencia_12345'));

      // Verificar hidratación del usuario autenticado
      final usuarioRecuperado = await authService.obtenerUsuarioActual();
      expect(usuarioRecuperado, isNotNull);
      expect(usuarioRecuperado!.nombre, equals('Elvis Mamani Valdivia'));
      expect(usuarioRecuperado.id, equals('2020068763'));
      expect(usuarioRecuperado.saldoCentimos, equals(15000));
    });

    test('Al cerrar sesión se eliminan las credenciales persistidas', () async {
      final authService = AuthService();
      const usuario = UsuarioModel(
        id: '2020068763',
        nombre: 'Elvis Mamani Valdivia',
        email: 'elvmamani@upt.pe',
        codigo: '2020068763',
        token: 'token_temporal',
        saldoCentimos: 15000,
      );

      await authService.guardarSesion(usuario: usuario, token: 'token_temporal');
      expect(await authService.estaAutenticado(), isTrue);

      // Cerrar sesión
      await authService.cerrarSesion();
      expect(await authService.estaAutenticado(), isFalse);
      expect(await authService.obtenerToken(), isNull);
    });
  });
}
