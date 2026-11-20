import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_moviles2_grupo03/models/curso.dart';
import 'package:proyecto_moviles2_grupo03/services/calculadora_simulacion_ciclo_service.dart';
import 'package:proyecto_moviles2_grupo03/services/calculos_multinivel.dart';

void main() {
  group('CalculadoraSimulacionCicloService (H36)', () {
    test('calcula correctamente el promedio simulado ponderado por créditos', () {
      final items = [
        const ItemSimulacionCurso(
          cursoId: 'c1',
          cursoNombre: 'Móviles II',
          creditos: 4,
          notaSimulada: 16.0,
        ),
        const ItemSimulacionCurso(
          cursoId: 'c2',
          cursoNombre: 'Sistemas Expertos',
          creditos: 2,
          notaSimulada: 10.0,
        ),
      ];

      // (16*4 + 10*2) / 6 = 84 / 6 = 14.0
      final resultado = CalculadoraSimulacionCicloService.calcularSimulacion(
        items: items,
      );

      expect(resultado.promedioSimulado, equals(14.0));
      expect(resultado.totalCreditos, equals(6));
      expect(resultado.creditosAprobados, equals(4)); // c1 aprobado
      expect(resultado.creditosDesaprobados, equals(2)); // c2 desaprobado (10.0 < 10.5)
      expect(resultado.cicloAprobado, isTrue);
    });

    test('aplica preset Minimo Aprobatorio asignando 10.5 a todos los cursos', () {
      final items = [
        const ItemSimulacionCurso(
          cursoId: 'c1',
          cursoNombre: 'Curso A',
          creditos: 4,
          notaSimulada: 18.0,
        ),
        const ItemSimulacionCurso(
          cursoId: 'c2',
          cursoNombre: 'Curso B',
          creditos: 3,
          notaSimulada: 05.0,
        ),
      ];

      final itemsModificados =
          CalculadoraSimulacionCicloService.aplicarPreset(
        items: items,
        preset: PresetSimulacion.minimoAprobatorio,
      );

      expect(itemsModificados.every((i) => i.notaSimulada == 10.5), isTrue);

      final resultado = CalculadoraSimulacionCicloService.calcularSimulacion(
        items: itemsModificados,
      );

      expect(resultado.promedioSimulado, equals(10.5));
      expect(resultado.creditosAprobados, equals(7));
      expect(resultado.creditosDesaprobados, equals(0));
    });

    test('aplica preset Meta Distincion y evalua Tercio Superior', () {
      final items = [
        const ItemSimulacionCurso(
          cursoId: 'c1',
          cursoNombre: 'Curso A',
          creditos: 4,
          notaActual: 17.0,
          notaSimulada: 17.0,
        ),
        const ItemSimulacionCurso(
          cursoId: 'c2',
          cursoNombre: 'Curso B',
          creditos: 3,
          notaActual: 14.0,
          notaSimulada: 14.0,
        ),
      ];

      final itemsDistincion =
          CalculadoraSimulacionCicloService.aplicarPreset(
        items: items,
        preset: PresetSimulacion.metaDistincion,
      );

      // El curso A mantiene 17.0 porque ya era mayor a 16.0; el curso B sube a 16.0
      expect(itemsDistincion[0].notaSimulada, equals(17.0));
      expect(itemsDistincion[1].notaSimulada, equals(16.0));

      final resultado = CalculadoraSimulacionCicloService.calcularSimulacion(
        items: itemsDistincion,
      );

      // (17*4 + 16*3)/7 = (68 + 48)/7 = 116/7 = 16.57 -> 16.6
      expect(resultado.promedioSimulado, equals(16.6));
      expect(resultado.esTercioSuperior, isTrue);
      expect(resultado.distanciaTercioSuperior, equals(0.0));
    });

    test('calcula impacto exacto en el PPA histórico acumulado', () {
      final items = [
        const ItemSimulacionCurso(
          cursoId: 'c1',
          cursoNombre: 'Tesis I',
          creditos: 20,
          notaSimulada: 16.0,
        ),
      ];

      // PPA Histórico previo: 14.0 con 40 créditos
      // Ciclo simulado: 16.0 con 20 créditos
      // Total ponderado: (14.0*40 + 16.0*20) / 60 = (560 + 320)/60 = 880/60 = 14.67 -> 14.7
      // Impacto = +0.7
      final resultado = CalculadoraSimulacionCicloService.calcularSimulacion(
        items: items,
        ppaHistorico: 14.0,
        creditosHistoricos: 40,
      );

      expect(resultado.ppaProyectado, equals(14.7));
      expect(resultado.impactoPpa, equals(0.7));
      expect(resultado.esTercioSuperior, isFalse);
      expect(resultado.distanciaTercioSuperior, equals(0.3)); // 15.0 - 14.7 = 0.3
    });

    test('inicializa items desde la lista de cursos y resultados de Firestore', () {
      final cursos = [
        Curso(id: 'c1', cicloId: 'ciclo-1', nombre: 'Curso 1', creditos: 4),
        Curso(id: 'c2', cicloId: 'ciclo-1', nombre: 'Curso 2', creditos: 0), // Default a 3
      ];

      final resultados = {
        'c1': const ResultadoCalculoCurso(
          promedioParcial: 15.4,
          porcentajeEvaluado: 50.0,
          estado: EstadoCalculoCurso.incompleto,
          mensajeEstado: 'En curso',
          notasPorUnidad: {},
          unidadCompleta: {},
        ),
      };

      final items = CalculadoraSimulacionCicloService.inicializarDesdeCursos(
        cursos: cursos,
        resultados: resultados,
      );

      expect(items.length, equals(2));
      expect(items[0].notaActual, equals(15.4));
      expect(items[0].notaSimulada, equals(15.4));
      expect(items[1].notaActual, isNull);
      expect(items[1].notaSimulada, equals(11.0)); // Default cuando no hay notas
      expect(items[1].creditosEfectivos, equals(3)); // Ajuste de créditos
    });

    test('maneja ciclo vacío sin cursos de forma segura', () {
      final resultado = CalculadoraSimulacionCicloService.calcularSimulacion(
        items: [],
      );

      expect(resultado.promedioSimulado, equals(0.0));
      expect(resultado.totalCreditos, equals(0));
      expect(resultado.esTercioSuperior, isFalse);
    });
  });
}
