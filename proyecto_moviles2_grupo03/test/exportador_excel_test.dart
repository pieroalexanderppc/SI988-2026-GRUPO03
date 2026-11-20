import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_moviles2_grupo03/models/curso.dart';
import 'package:proyecto_moviles2_grupo03/services/calculos_multinivel.dart';
import 'package:proyecto_moviles2_grupo03/services/exportador_excel_service.dart';

void main() {
  group('ExportadorExcelService (H35)', () {
    final cursos = <Curso>[
      Curso(
        id: 'c1',
        cicloId: 'ciclo-1',
        nombre: 'Soluciones Móviles II',
        creditos: 4,
      ),
      Curso(
        id: 'c2',
        cicloId: 'ciclo-1',
        nombre: 'Taller de Sistemas de Información',
        creditos: 3,
      ),
      Curso(
        id: 'c3',
        cicloId: 'ciclo-1',
        nombre: 'Auditoría y Seguridad',
        creditos: 3,
      ),
    ];

    final resultados = <String, ResultadoCalculoCurso>{
      'c1': const ResultadoCalculoCurso(
        promedioParcial: 17.5,
        porcentajeEvaluado: 75.0,
        estado: EstadoCalculoCurso.incompleto,
        mensajeEstado: 'En curso',
        notasPorUnidad: {},
        unidadCompleta: {},
      ),
      'c2': const ResultadoCalculoCurso(
        promedioParcial: 10.0,
        porcentajeEvaluado: 50.0,
        estado: EstadoCalculoCurso.incompleto,
        mensajeEstado: 'En riesgo',
        notasPorUnidad: {},
        unidadCompleta: {},
      ),
      'c3': const ResultadoCalculoCurso(
        estado: EstadoCalculoCurso.incompleto,
        mensajeEstado: 'Sin notas',
        notasPorUnidad: {},
        unidadCompleta: {},
      ),
    };

    test('genera un archivo .xlsx válido con cabecera de archivo ZIP (PK)', () {
      final bytes = ExportadorExcelService.generarExcel(
        cicloNombre: '2026-II',
        cursos: cursos,
        resultados: resultados,
        promedioCiclo: 14.5,
        totalCreditos: 10,
        nombreEstudiante: 'Elvis Mamani',
        correoEstudiante: 'elvmamani@upt.pe',
      );

      expect(bytes, isNotEmpty);
      // Cabecera mágica ZIP: 0x50, 0x4B, 0x03, 0x04 ("PK..")
      expect(bytes[0], equals(0x50));
      expect(bytes[1], equals(0x4B));
      expect(bytes[2], equals(0x03));
      expect(bytes[3], equals(0x04));

      // Verificamos que se descomprima correctamente con las partes OOXML
      final zip = ZipDecoder().decodeBytes(bytes);
      final nombresArchivos = zip.files.map((f) => f.name).toList();

      expect(nombresArchivos, contains('[Content_Types].xml'));
      expect(nombresArchivos, contains('xl/workbook.xml'));
      expect(nombresArchivos, contains('xl/styles.xml'));
      expect(nombresArchivos, contains('xl/worksheets/sheet1.xml'));

      // Verificar que la hoja contenga fórmulas dinámicas SUMPRODUCT y datos
      final sheetFile = zip.files.firstWhere((f) => f.name == 'xl/worksheets/sheet1.xml');
      final sheetContent = utf8.decode(sheetFile.content as List<int>);

      expect(sheetContent, contains('SUMPRODUCT'));
      expect(sheetContent, contains('Soluciones Móviles II'));
      expect(sheetContent, contains('PONDERA - REPORTE DE AVANCE ACADÉMICO'));
    });

    test('genera un archivo CSV con BOM UTF-8 y caracteres especiales correctos', () {
      final csv = ExportadorExcelService.generarCsv(
        cicloNombre: '2026-II',
        cursos: cursos,
        resultados: resultados,
        promedioCiclo: 14.5,
        totalCreditos: 10,
        nombreEstudiante: 'Elvis Mamani',
        correoEstudiante: 'elvmamani@upt.pe',
      );

      expect(csv, isNotEmpty);
      // Empieza con BOM UTF-8 (\uFEFF)
      expect(csv.startsWith('\uFEFF'), isTrue);

      expect(csv, contains('PONDERA - REPORTE DE AVANCE ACADÉMICO'));
      expect(csv, contains('2026-II'));
      expect(csv, contains('Elvis Mamani'));
      expect(csv, contains('"Soluciones Móviles II";4;75.0%;17.5;En curso (Aprobado)'));
      expect(csv, contains('"Taller de Sistemas de Información";3;50.0%;10.0;En riesgo'));
      expect(csv, contains('"Auditoría y Seguridad";3;0.0%;--;Sin notas'));
      expect(csv, contains('PROMEDIO PONDERADO:;14.50;;;'));
    });

    test('soporta ciclo vacío sin cursos sin lanzar excepciones', () {
      final bytes = ExportadorExcelService.generarExcel(
        cicloNombre: 'Ciclo Vacío',
        cursos: [],
        resultados: {},
        promedioCiclo: null,
        totalCreditos: 0,
      );

      expect(bytes, isNotEmpty);

      final csv = ExportadorExcelService.generarCsv(
        cicloNombre: 'Ciclo Vacío',
        cursos: [],
        resultados: {},
        promedioCiclo: null,
        totalCreditos: 0,
      );

      expect(csv, contains('Ciclo Vacío'));
      expect(csv, contains('PROMEDIO PONDERADO:;--;;;'));
    });
  });
}
