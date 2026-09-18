import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_moviles2_grupo03/models/usuario_model.dart';
import 'package:proyecto_moviles2_grupo03/services/usuario_service.dart';

void main() {
  late UsuarioService usuarioService;

  setUp(() {
    usuarioService = UsuarioService();
  });

  group('Punto 4 - Tres Pruebas de Lectura y Parseo en Terminal', () {
    // (a) Carga de entidad: verificar que un JSON estructurado correctamente
    //     hidrata la entidad con todos sus atributos íntegros.
    test('(a) Carga de entidad: JSON valido hidrata la entidad con todos sus atributos integros', () {
      final jsonValido = {
        'id': '2020068763',
        'nombre': 'Elvis Mamani Valdivia',
        'email': 'elvmamani@upt.pe',
        'codigo': '2020068763',
        'token': 'jwt_upt_elvis_2026',
        'saldoCentimos': 15000,
        'saldoExacto': '150.00',
        'estado': 'ACTIVO',
        'carrera': 'Ingeniería de Sistemas',
        'ciclo': 'IX Ciclo',
      };

      final usuario = UsuarioModel.fromJson(jsonValido);

      // Verificación de integridad total de atributos
      expect(usuario.id, equals('2020068763'));
      expect(usuario.nombre, equals('Elvis Mamani Valdivia'));
      expect(usuario.email, equals('elvmamani@upt.pe'));
      expect(usuario.codigo, equals('2020068763'));
      expect(usuario.token, equals('jwt_upt_elvis_2026'));
      expect(usuario.saldoCentimos, equals(15000));
      expect(usuario.saldoExacto, equals('150.00'));
      expect(usuario.saldoFormateado, equals('S/ 150.00'));
      expect(usuario.estado, equals('ACTIVO'));
      expect(usuario.carrera, equals('Ingeniería de Sistemas'));
      expect(usuario.ciclo, equals('IX Ciclo'));
    });

    // (b) Estado exitoso: comprobar que la carga correcta sitúa a la app en un
    //     estado final con datos listos para renderizar.
    test('(b) Estado exitoso: la carga correcta situa a la app en estado final con datos listos para renderizar', () {
      final jsonValido = {
        'id': '2020068763',
        'nombre': 'Elvis Mamani Valdivia',
        'saldo': '250.75',
      };

      final resultado = usuarioService.procesarPayload(jsonValido);

      // Verificación de transición al estado exitoso
      expect(resultado.estado, equals(EstadoCarga.exitoso));
      expect(resultado.datosListosParaRenderizar, isTrue);
      expect(resultado.usuario, isNotNull);
      expect(resultado.usuario!.nombre, equals('Elvis Mamani Valdivia'));
      expect(resultado.usuario!.saldoExacto, equals('250.75'));
      expect(resultado.reintentosDisparados, equals(0));
    });

    // (c) Manejo de carga fallida: comprobar que un payload inaceptable posiciona
    //     el flujo en estado de error sin disparar reintentos.
    test('(c) Manejo de carga fallida: payload inaceptable posiciona flujo en estado error sin disparar reintentos', () {
      // Casos de payloads inaceptables: null, corrupto o vacío
      const String payloadCorrupto = '<html><body>502 Bad Gateway</body></html>';

      final resultado1 = usuarioService.procesarPayload(payloadCorrupto);
      expect(resultado1.estado, equals(EstadoCarga.fallido));
      expect(resultado1.datosListosParaRenderizar, isFalse);
      expect(resultado1.reintentosDisparados, equals(0),
          reason: 'No debe entrar en bucle de reintentos infinitos');
      expect(resultado1.mensajeError, contains('Payload inaceptable'));

      // Payload nulo
      final resultado2 = usuarioService.procesarPayload(null);
      expect(resultado2.estado, equals(EstadoCarga.fallido));
      expect(resultado2.datosListosParaRenderizar, isFalse);
      expect(resultado2.reintentosDisparados, equals(0));

      // Payload objeto vacío
      final resultado3 = usuarioService.procesarPayload({});
      expect(resultado3.estado, equals(EstadoCarga.fallido));
      expect(resultado3.datosListosParaRenderizar, isFalse);
      expect(resultado3.reintentosDisparados, equals(0));
    });
  });
}
