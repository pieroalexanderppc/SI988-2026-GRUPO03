import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_moviles2_grupo03/models/usuario_model.dart';

void main() {
  group('Punto 3 - Tolerancia a Valores Nulos y Claves No Previstas', () {
    test('Campos opcionales ausentes o nulos asumen valores seguros por defecto', () {
      // Payload con valores explícitamente nulos y campos faltantes
      final Map<String, dynamic> jsonConNulos = {
        'id': null,
        'nombre': null,
        'email': null,
        'codigo': null,
        'saldo': null,
        'estado': null,
        'carrera': null,
        'ciclo': null,
      };

      final usuario = UsuarioModel.fromJson(jsonConNulos);

      // Verificación de defaults seguros que evitan colapso de pantalla
      expect(usuario.id, equals('0'));
      expect(usuario.nombre, equals('Elvis Mamani Valdivia'));
      expect(usuario.email, equals('elvmamani@upt.pe'));
      expect(usuario.codigo, equals('2020068763'));
      expect(usuario.saldoCentimos, equals(0));
      expect(usuario.saldoExacto, equals('0.00'));
      expect(usuario.saldoFormateado, equals('S/ 0.00'));
      expect(usuario.estado, equals('ACTIVO'));
      expect(usuario.carrera, equals('Ingeniería de Sistemas'));
      expect(usuario.ciclo, equals('IX Ciclo'));
    });

    test('Claves adicionales no previstas son ignoradas silenciosamente', () {
      // Payload con claves raras/inesperadas que una API podría inyectar
      final Map<String, dynamic> jsonConClavesSobrantes = {
        'id': '2020068763',
        'nombre': 'Elvis Mamani Valdivia',
        'saldo': '180.50',
        'campo_desconocido_1': 'dato_ignorado',
        'payload_debug': {'timestamp': 1726670000, 'servidor': 'prod-01'},
        'versiones_anteriores': [1, 2, 3],
        'token_temporal_api': 'xyz-999',
      };

      // Debe procesar sin arrojar excepciones ni NoSuchMethodError
      expect(() => UsuarioModel.fromJson(jsonConClavesSobrantes), returnsNormally);

      final usuario = UsuarioModel.fromJson(jsonConClavesSobrantes);
      expect(usuario.id, equals('2020068763'));
      expect(usuario.nombre, equals('Elvis Mamani Valdivia'));
      expect(usuario.saldoCentimos, equals(18050));
      expect(usuario.saldoExacto, equals('180.50'));
    });

    test('Payload nulo absoluto (null) retorna entidad fallback segura', () {
      final usuario = UsuarioModel.fromJson(null);

      expect(usuario, isNotNull);
      expect(usuario.id, equals('0'));
      expect(usuario.nombre, equals('Estudiante Invitado'));
      expect(usuario.saldoCentimos, equals(0));
      expect(usuario.saldoFormateado, equals('S/ 0.00'));
    });
  });
}
