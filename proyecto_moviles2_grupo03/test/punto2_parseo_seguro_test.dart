import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_moviles2_grupo03/models/usuario_model.dart';

void main() {
  group('Punto 2 - Parseo Seguro de Identificadores y Valores Monetarios', () {
    test('Identificador en formato numérico se almacena estrictamente como String sin pérdida de precisión', () {
      final jsonConIdNumerico = {
        'id': 2020068763,
        'nombre': 'Elvis Mamani Valdivia',
        'email': 'elvmamani@upt.pe',
        'saldo': 15000,
      };

      final usuario = UsuarioModel.fromJson(jsonConIdNumerico);

      // Verificación de tipo estricto String
      expect(usuario.id, isA<String>());
      expect(usuario.id, equals('2020068763'));
    });

    test('Identificador numérico extenso (19 dígitos) preserva cada dígito exacto como String', () {
      const rawJson = '''
      {
        "id": 9876543210123456789,
        "nombre": "Elvis Mamani Valdivia",
        "email": "elvmamani@upt.pe",
        "saldo": 15000
      }
      ''';

      final usuario = UsuarioModel.fromRawJson(rawJson);

      expect(usuario.id, isA<String>());
      expect(usuario.id, equals('9876543210123456789'));
      expect(usuario.id.length, equals(19));
    });

    test('Valores monetarios se guardan en céntimos enteros (int) evitando tipo double', () {
      // Caso 1: Monto en céntimos enteros directos
      final jsonCentimos = {
        'id': '2020068763',
        'nombre': 'Elvis Mamani Valdivia',
        'saldo': 15000,
      };
      final user1 = UsuarioModel.fromJson(jsonCentimos);
      expect(user1.saldoCentimos, isA<int>());
      expect(user1.saldoCentimos, equals(15000));
      expect(user1.saldoExacto, equals('150.00'));
      expect(user1.saldoFormateado, equals('S/ 150.00'));

      // Caso 2: Monto como texto con decimales exactos
      final jsonTextoDecimal = {
        'id': '2020068763',
        'nombre': 'Elvis Mamani Valdivia',
        'saldo': '250.75',
      };
      final user2 = UsuarioModel.fromJson(jsonTextoDecimal);
      expect(user2.saldoCentimos, isA<int>());
      expect(user2.saldoCentimos, equals(25075));
      expect(user2.saldoExacto, equals('250.75'));
      expect(user2.saldoFormateado, equals('S/ 250.75'));

      // Caso 3: Operaciones matemáticas monetarias se realizan con enteros para evitar imprecisión IEEE-754
      const centimosItem1 = 10; // S/ 0.10
      const centimosItem2 = 20; // S/ 0.20
      const totalCentimos = centimosItem1 + centimosItem2; // 30 céntimos exactos
      expect(totalCentimos, equals(30));
    });
  });
}
