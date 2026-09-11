import 'package:flutter_test/flutter_test.dart';
import '../lib/models/componente_evaluacion.dart';
import '../lib/services/calculadora_promedio.dart';

void main() {
  group('Pruebas Unitarias CalculadoraPromedio (H02)', () {
    test('Calcula correctamente el promedio ponderado (pesos suman 100)', () {
      final lista = [
        ComponenteEvaluacion(nombre: 'Evaluación 1', nota: 14.0, peso: 50.0),
        ComponenteEvaluacion(nombre: 'Evaluación 2', nota: 16.0, peso: 50.0),
      ];
      final promedio = CalculadoraPromedio.calcularPromedio(lista);
      expect(promedio, 15.0);
      expect(CalculadoraPromedio.esAprobado(promedio!), isTrue);
    });

    test('Retorna null si la suma de pesos no da 100', () {
      final lista = [
        ComponenteEvaluacion(nombre: 'Evaluación 1', nota: 12.0, peso: 30.0),
        ComponenteEvaluacion(nombre: 'Evaluación 2', nota: 14.0, peso: 30.0),
      ];
      expect(CalculadoraPromedio.calcularPromedio(lista), isNull);
    });

    test('Retorna null si la lista contiene menos de 2 componentes', () {
      final lista = [
        ComponenteEvaluacion(nombre: 'Evaluación Única', nota: 15.0, peso: 100.0),
      ];
      expect(CalculadoraPromedio.calcularPromedio(lista), isNull);
    });

    test('Evalúa correctamente el límite de aprobación (10.5)', () {
      expect(CalculadoraPromedio.esAprobado(10.5), isTrue);
      expect(CalculadoraPromedio.esAprobado(10.49), isFalse);
    });
  });
}