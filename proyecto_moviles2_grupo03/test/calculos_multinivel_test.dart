import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_moviles2_grupo03/models/nota.dart';
import 'package:proyecto_moviles2_grupo03/models/tipo_evaluacion.dart';
import 'package:proyecto_moviles2_grupo03/models/unidad.dart';
import 'package:proyecto_moviles2_grupo03/services/calculos_multinivel.dart';

void main() {
  group('CalculosMultinivel - Cálculo multinivel completo', () {
    test('Calcula correctamente: Promedio Tipo -> Nota Unidad -> Nota Final Curso a 1 decimal', () {
      // Configuración Unidad 1 (50% del curso)
      final u1 = Unidad(id: 'u1', nombre: 'Unidad 1', cursoId: 'c1', porcentaje: 50.0);
      final tipoLabU1 = TipoEvaluacion(id: 't1', nombre: 'Laboratorios', porcentaje: 40.0);
      final tipoExamU1 = TipoEvaluacion(id: 't2', nombre: 'Examen', porcentaje: 60.0);

      final estU1 = EstructuraUnidad(
        unidad: u1,
        tipos: [
          EstructuraTipoEvaluacion(
            tipo: tipoLabU1,
            notas: [
              Nota(id: 'n1', valor: 14.0, tipoEvaluacionId: 't1'),
              Nota(id: 'n2', valor: 16.0, tipoEvaluacionId: 't1'), // Promedio = 15.0
            ],
          ),
          EstructuraTipoEvaluacion(
            tipo: tipoExamU1,
            notas: [
              Nota(id: 'n3', valor: 18.0, tipoEvaluacionId: 't2'), // Promedio = 18.0
            ],
          ),
        ],
      );
      // Nota U1 esperada = 15.0 * 0.40 + 18.0 * 0.60 = 6.0 + 10.8 = 16.8

      // Configuración Unidad 2 (50% del curso)
      final u2 = Unidad(id: 'u2', nombre: 'Unidad 2', cursoId: 'c1', porcentaje: 50.0);
      final tipoProyU2 = TipoEvaluacion(id: 't3', nombre: 'Proyecto', porcentaje: 50.0);
      final tipoExamU2 = TipoEvaluacion(id: 't4', nombre: 'Examen Final', porcentaje: 50.0);

      final estU2 = EstructuraUnidad(
        unidad: u2,
        tipos: [
          EstructuraTipoEvaluacion(
            tipo: tipoProyU2,
            notas: [
              Nota(id: 'n4', valor: 15.0, tipoEvaluacionId: 't3'), // Promedio = 15.0
            ],
          ),
          EstructuraTipoEvaluacion(
            tipo: tipoExamU2,
            notas: [
              Nota(id: 'n5', valor: 13.0, tipoEvaluacionId: 't4'), // Promedio = 13.0
            ],
          ),
        ],
      );
      // Nota U2 esperada = 15.0 * 0.50 + 13.0 * 0.50 = 7.5 + 6.5 = 14.0

      // Nota Curso esperada = 16.8 * 0.50 + 14.0 * 0.50 = 8.4 + 7.0 = 15.4

      final resultado = CalculosMultinivel.calcular([estU1, estU2]);

      expect(resultado.estado, EstadoCalculoCurso.completo);
      expect(resultado.notaFinal, 15.4);
      expect(resultado.esAprobado, isTrue);
      expect(resultado.notasPorUnidad['u1'], closeTo(16.8, 0.001));
      expect(resultado.notasPorUnidad['u2'], closeTo(14.0, 0.001));
      expect(resultado.unidadCompleta['u1'], isTrue);
      expect(resultado.unidadCompleta['u2'], isTrue);
    });

    test('Redondea correctamente a 1 decimal', () {
      expect(CalculosMultinivel.redondearUnDecimal(15.44), 15.4);
      expect(CalculosMultinivel.redondearUnDecimal(15.46), 15.5);
      expect(CalculosMultinivel.redondearUnDecimal(10.0), 10.0);
    });
  });

  group('CalculosMultinivel - Manejo de información incompleta', () {
    test('Retorna incompleto si una unidad no tiene notas registradas', () {
      final u1 = Unidad(id: 'u1', nombre: 'Unidad 1', cursoId: 'c1', porcentaje: 50.0);
      final u2 = Unidad(id: 'u2', nombre: 'Unidad 2', cursoId: 'c1', porcentaje: 50.0);

      final estU1 = EstructuraUnidad(
        unidad: u1,
        tipos: [
          EstructuraTipoEvaluacion(
            tipo: TipoEvaluacion(id: 't1', nombre: 'Examen', porcentaje: 100.0),
            notas: [Nota(id: 'n1', valor: 16.0, tipoEvaluacionId: 't1')],
          ),
        ],
      );

      final estU2 = EstructuraUnidad(
        unidad: u2,
        tipos: [
          EstructuraTipoEvaluacion(
            tipo: TipoEvaluacion(id: 't2', nombre: 'Examen', porcentaje: 100.0),
            notas: [], // Sin notas
          ),
        ],
      );

      final resultado = CalculosMultinivel.calcular([estU1, estU2]);

      expect(resultado.estado, EstadoCalculoCurso.incompleto);
      expect(resultado.notaFinal, isNull, reason: 'No debe mostrar un cálculo final erróneo');
      expect(resultado.mensajeEstado, contains('Faltan notas en "Unidad 2"'));
      expect(resultado.notaAcumulada, 8.0, reason: 'Debe mostrar la nota acumulada de U1 (16 * 0.5)');
    });

    test('Retorna incompleto si las unidades no suman 100%', () {
      final u1 = Unidad(id: 'u1', nombre: 'Unidad 1', cursoId: 'c1', porcentaje: 40.0);
      final u2 = Unidad(id: 'u2', nombre: 'Unidad 2', cursoId: 'c1', porcentaje: 40.0);

      final estU1 = EstructuraUnidad(
        unidad: u1,
        tipos: [
          EstructuraTipoEvaluacion(
            tipo: TipoEvaluacion(id: 't1', nombre: 'Examen', porcentaje: 100.0),
            notas: [Nota(id: 'n1', valor: 15.0, tipoEvaluacionId: 't1')],
          ),
        ],
      );

      final estU2 = EstructuraUnidad(
        unidad: u2,
        tipos: [
          EstructuraTipoEvaluacion(
            tipo: TipoEvaluacion(id: 't2', nombre: 'Examen', porcentaje: 100.0),
            notas: [Nota(id: 'n2', valor: 15.0, tipoEvaluacionId: 't2')],
          ),
        ],
      );

      final resultado = CalculosMultinivel.calcular([estU1, estU2]);

      expect(resultado.estado, EstadoCalculoCurso.incompleto);
      expect(resultado.notaFinal, isNull);
      expect(resultado.mensajeEstado, contains('Los pesos de las unidades deben sumar 100%'));
    });

    test('Retorna sinDatos si no hay unidades', () {
      final resultado = CalculosMultinivel.calcular([]);
      expect(resultado.estado, EstadoCalculoCurso.sinDatos);
      expect(resultado.notaFinal, isNull);
    });
  });
}
