import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_moviles2_grupo03/models/usuario_model.dart';

void main() {
  group('Punto 5 - Pruebas Unitarias con JSON en Texto Crudo (String Literals)', () {
    // (a) Probar que un JSON que incluye claves sobrantes y un campo explícitamente nulo
    //     se deserializa correctamente sin generar fallas ni interrumpir el flujo.
    test('(a) JSON crudo con claves sobrantes y campo nulo deserializa de forma segura', () {
      const String rawJsonConClavesSobrantesYNulo = '''{
  "id": "2020068763",
  "nombre": "Elvis Mamani Valdivia",
  "email": null,
  "saldo": "150.50",
  "campo_no_previsto_1": "valor_aleatorio_no_mapeado",
  "metadata_interna": {
    "servidor": "api-cluster-01",
    "latencia_ms": 42
  },
  "tokens_adicionales": ["tk_01", "tk_02"],
  "flag_experimental": true
}''';

      expect(() => UsuarioModel.fromRawJson(rawJsonConClavesSobrantesYNulo), returnsNormally);

      final usuario = UsuarioModel.fromRawJson(rawJsonConClavesSobrantesYNulo);

      expect(usuario.id, equals('2020068763'));
      expect(usuario.nombre, equals('Elvis Mamani Valdivia'));
      expect(usuario.email, equals('elvmamani@upt.pe'));
      expect(usuario.saldoCentimos, equals(15050));
      expect(usuario.saldoExacto, equals('150.50'));
      expect(usuario.saldoFormateado, equals('S/ 150.50'));
      expect(usuario.estado, equals('ACTIVO'));
    });

    // (b) Probar que un identificador numérico extenso (19 dígitos) preserva cada dígito
    //     con total exactitud y que un cálculo monetario no sufre alteración en sus decimales/céntimos.
    test('(b) JSON crudo con ID de 19 digitos y monto monetario preserva exactitud absoluta', () {
      const String rawJsonId19DigitosYSaldo = '''{
  "id": 9876543210123456789,
  "nombre": "Elvis Mamani Valdivia",
  "codigo": "2020068763",
  "saldo": "2850.75"
}''';

      final usuario = UsuarioModel.fromRawJson(rawJsonId19DigitosYSaldo);

      expect(usuario.id, equals('9876543210123456789'));
      expect(usuario.id.length, equals(19));
      expect(usuario.id.endsWith('789'), isTrue);
      expect(usuario.saldoCentimos, equals(285075));
      expect(usuario.saldoExacto, equals('2850.75'));
      expect(usuario.saldoFormateado, equals('S/ 2850.75'));
    });
  });
}
