import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_moviles2_grupo03/services/lector_reporte_notas.dart';

/// Convierte frases en palabras con cajas aproximadas (7 px por caracter).
List<PalabraOcr> fila(double y, List<(double, String)> celdas, {double alto = 12}) {
  final palabras = <PalabraOcr>[];
  for (final (x, texto) in celdas) {
    var cursor = x;
    for (final w in texto.split(' ')) {
      final ancho = w.length * 7.0;
      palabras.add(PalabraOcr(w, cursor, y, cursor + ancho, y + alto));
      cursor += ancho + 4;
    }
  }
  return palabras;
}

List<PalabraOcr> encabezado(double y) => fila(y, [
      (80, 'Unidad'),
      (153, 'Criterio'),
      (255, 'Peso C.'),
      (301, 'Peso U.'),
      (348, 'Nota'),
      (385, 'Fecha'),
      (485, 'Descripción'),
    ]);

/// Reporte de "Taller de Tesis II" (imagen de referencia del issue H19).
List<PalabraOcr> reporteTallerTesis() => [
      ...fila(10, [(12, 'TALLER DE TESIS II / TRABAJO DE INVESTIGACIÓN')]),
      ...encabezado(40),
      ...fila(68, [(80, 'Unidad I'), (301, '30 %')]),
      ...fila(95, [(153, 'Evaluacion 01'), (255, '10 %'), (348, '13'), (387, 'Oct 09 2026'), (487, 'Actitudinal')]),
      ...fila(112, [(387, '01:47:00AM')]),
      ...fila(136, [(153, 'Evaluacion 02'), (255, '25 %'), (348, '13'), (387, 'Oct 12 2026'), (487, 'Trabajos de encargado')]),
      ...fila(153, [(387, '11:24:00:000PM')]),
      ...fila(178, [(153, 'Evaluacion 03'), (255, '35 %'), (348, '13'), (387, 'Oct 12 2026'), (487, 'Trabajo de investigación')]),
      ...fila(195, [(387, '11:59:00:000PM')]),
      ...fila(220, [(153, 'Evaluacion 04'), (255, '30 %'), (348, '18'), (387, 'Oct 09 2026'), (487, 'Examen de unidad')]),
      ...fila(237, [(387, '01:14:00:000AM')]),
      ...fila(262, [(262, '100 %'), (348, '14.50')]),
      ...encabezado(305),
      ...fila(332, [(80, 'Unidad II'), (301, '35 %')]),
      ...fila(358, [(153, 'Evaluacion 01'), (255, '10 %'), (482, 'Actitudinal')]),
      ...fila(386, [(153, 'Evaluacion 02'), (255, '25 %'), (482, 'Trabajos de encargado')]),
      ...fila(412, [(153, 'Evaluacion 03'), (255, '40 %'), (482, 'Trabajo de investigación')]),
      ...fila(440, [(153, 'Evaluacion 04'), (255, '25 %'), (482, 'Examen de unidad')]),
      ...fila(465, [(262, '100 %'), (348, '0.00')]),
      ...encabezado(510),
      ...fila(537, [(80, 'Unidad III'), (301, '35 %')]),
      ...fila(563, [(153, 'Evaluacion 01'), (255, '10 %'), (482, 'Actitudinal')]),
      ...fila(590, [(153, 'Evaluacion 02'), (255, '25 %'), (482, 'Trabajos de encargado')]),
      ...fila(616, [(153, 'Evaluacion 03'), (255, '45 %'), (482, 'Trabajo de investigación')]),
      ...fila(643, [(153, 'Evaluacion 04'), (255, '20 %'), (482, 'Examen de unidad')]),
      ...fila(670, [(262, '100 %'), (348, '0.00')]),
      ...fila(712, [(225, 'El promedio actual del curso es: 4')]),
    ];

void main() {
  group('LectorReporteNotas - reporte del portal', () {
    final reporte = LectorReporteNotas.leer(reporteTallerTesis());

    test('Lee el nombre del curso', () {
      expect(reporte.curso, 'TALLER DE TESIS II / TRABAJO DE INVESTIGACIÓN');
    });

    test('Lee las 3 unidades con su peso y en numeros arabigos', () {
      expect(reporte.unidades.map((u) => u.nombre), ['Unidad 1', 'Unidad 2', 'Unidad 3']);
      expect(reporte.unidades.map((u) => u.peso), [30, 35, 35]);
    });

    test('Lee los criterios con peso, nota y descripcion', () {
      final u1 = reporte.unidades[0].criterios;
      expect(u1.length, 4);
      expect(u1.map((c) => c.peso), [10, 25, 35, 30]);
      expect(u1.map((c) => c.nota), [13, 13, 13, 18]);
      expect(u1[0].nombre, 'Evaluacion 01');
      expect(u1[0].descripcion, 'Actitudinal');
      expect(u1[3].descripcion, 'Examen de unidad');
    });

    test('Las evaluaciones sin nota quedan pendientes, no en 0', () {
      for (final u in reporte.unidades.skip(1)) {
        expect(u.criterios.length, 4);
        expect(u.criterios.every((c) => c.nota == null), isTrue);
      }
      expect(reporte.cantidadNotas, 4);
    });

    test('Ignora horas, totales y el pie del reporte', () {
      final todos = reporte.unidades.expand((u) => u.criterios).toList();
      expect(todos.length, 12);
      expect(todos.any((c) => c.descripcion.contains(':')), isFalse);
      expect(reporte.unidades[2].criterios.map((c) => c.peso), [10, 25, 45, 20]);
    });
  });

  group('LectorReporteNotas - OCR imperfecto', () {
    test('Corrige O por 0 y comas en celdas numericas', () {
      final r = LectorReporteNotas.leer([
        ...encabezado(0),
        ...fila(30, [(80, 'Unidad I'), (301, '3O %')]),
        ...fila(60, [(153, 'Evaluacion 01'), (255, '1O%'), (348, '15,5'), (487, 'Examen')]),
      ]);
      expect(r.unidades.single.peso, 30);
      expect(r.unidades.single.criterios.single.peso, 10);
      expect(r.unidades.single.criterios.single.nota, 15.5);
    });

    test('Sin encabezado detectado, interpreta la fila completa', () {
      final r = LectorReporteNotas.leer([
        ...fila(30, [(80, 'Unidad I'), (301, '30 %')]),
        ...fila(60, [(153, 'Evaluacion 01'), (255, '40 %'), (348, '16'), (387, 'Oct 09 2026'), (487, 'Examen de unidad')]),
      ]);
      final c = r.unidades.single.criterios.single;
      expect(c.peso, 40);
      expect(c.nota, 16);
      expect(c.descripcion, 'Examen de unidad');
    });

    test('Una imagen que no es un reporte devuelve un reporte vacio', () {
      final r = LectorReporteNotas.leer(fila(10, [(10, 'Hola mundo'), (200, 'esto no es una tabla')]));
      expect(r.vacio, isTrue);
    });
  });
}
