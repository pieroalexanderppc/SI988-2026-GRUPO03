import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_moviles2_grupo03/models/curso.dart';
import 'package:proyecto_moviles2_grupo03/services/calculos_multinivel.dart';
import 'package:proyecto_moviles2_grupo03/services/reporte_ciclo_pdf.dart';

void main() {
  group('ReporteCicloPdf (H22)', () {
    test('genera un documento PDF válido con bytes de cabecera %PDF-', () async {
      final cursos = <Curso>[
        Curso(
          id: 'c1',
          cicloId: 'ciclo-1',
          nombre: 'Móviles II',
          creditos: 4,
        ),
        Curso(
          id: 'c2',
          cicloId: 'ciclo-1',
          nombre: 'Base de Datos Avanzada',
          creditos: 3,
        ),
      ];

      final resultados = <String, ResultadoCalculoCurso>{
        'c1': const ResultadoCalculoCurso(
          promedioParcial: 16.5,
          porcentajeEvaluado: 60.0,
          estado: EstadoCalculoCurso.incompleto,
          mensajeEstado: 'En curso',
          notasPorUnidad: {},
          unidadCompleta: {},
        ),
        'c2': const ResultadoCalculoCurso(
          promedioParcial: 9.8,
          porcentajeEvaluado: 50.0,
          estado: EstadoCalculoCurso.incompleto,
          mensajeEstado: 'En riesgo',
          notasPorUnidad: {},
          unidadCompleta: {},
        ),
      };

      final pdfBytes = await ReporteCicloPdf.generarPdf(
        cicloNombre: '2026-I',
        cursos: cursos,
        resultados: resultados,
        promedioCiclo: 13.63,
        totalCreditos: 7,
        fechaEmision: DateTime(2026, 10, 22, 16, 0),
      );

      expect(pdfBytes, isNotEmpty);
      // Validar que comience con la firma de cabecera PDF '%PDF-'
      final encabezado = ascii.decode(pdfBytes.sublist(0, 5));
      expect(encabezado, equals('%PDF-'));
    });

    test('genera PDF correctamente cuando ningún curso tiene notas aún', () async {
      final cursos = <Curso>[
        Curso(
          id: 'c1',
          cicloId: 'ciclo-1',
          nombre: 'Tesis I',
          creditos: 5,
        ),
      ];

      final resultados = <String, ResultadoCalculoCurso>{
        'c1': const ResultadoCalculoCurso(
          promedioParcial: null,
          notaFinal: null,
          porcentajeEvaluado: 0.0,
          estado: EstadoCalculoCurso.sinDatos,
          mensajeEstado: 'Sin notas',
          notasPorUnidad: {},
          unidadCompleta: {},
        ),
      };

      final pdfBytes = await ReporteCicloPdf.generarPdf(
        cicloNombre: '2026-II',
        cursos: cursos,
        resultados: resultados,
        promedioCiclo: null,
        totalCreditos: 5,
      );

      expect(pdfBytes, isNotEmpty);
      final encabezado = ascii.decode(pdfBytes.sublist(0, 5));
      expect(encabezado, equals('%PDF-'));
    });
  });
}
