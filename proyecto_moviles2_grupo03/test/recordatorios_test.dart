import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_moviles2_grupo03/models/recordatorio_evaluacion.dart';
import 'package:proyecto_moviles2_grupo03/screens/recordatorios_screen.dart';
import 'package:proyecto_moviles2_grupo03/services/recordatorios_service.dart';

void main() {
  group('H26 - Modelo RecordatorioEvaluacion', () {
    test('Serialización y deserialización toMap y fromMap', () {
      final fecha = DateTime(2026, 11, 20, 15, 30);
      final creadoEn = DateTime(2026, 11, 5, 10, 0);

      final recordatorio = RecordatorioEvaluacion(
        id: 'rec_123',
        titulo: 'Examen Final de Móviles',
        cursoId: 'curso_01',
        cursoNombre: 'Soluciones Móviles II',
        unidadId: 'u2',
        unidadNombre: 'Unidad 2',
        fecha: fecha,
        descripcion: 'Estudiar Flutter, Firebase y ML Kit',
        completado: false,
        creadoEn: creadoEn,
      );

      final map = recordatorio.toMap();
      expect(map['titulo'], 'Examen Final de Móviles');
      expect(map['cursoNombre'], 'Soluciones Móviles II');
      expect(map['completado'], false);
      expect((map['fecha'] as Timestamp).toDate(), fecha);

      final reconstruido = RecordatorioEvaluacion.fromMap('rec_123', map);
      expect(reconstruido.id, 'rec_123');
      expect(reconstruido.titulo, 'Examen Final de Móviles');
      expect(reconstruido.cursoNombre, 'Soluciones Móviles II');
      expect(reconstruido.fecha.year, 2026);
      expect(reconstruido.fecha.month, 11);
      expect(reconstruido.fecha.day, 20);
      expect(reconstruido.fecha.hour, 15);
      expect(reconstruido.fecha.minute, 30);
    });

    test('Cálculo de estaVencido, esHoy, esManana y días restantes', () {
      final ahora = DateTime.now();

      final recordatorioHoy = RecordatorioEvaluacion(
        id: '1',
        titulo: 'Quiz 1',
        cursoId: 'c1',
        cursoNombre: 'Curso 1',
        fecha: DateTime(ahora.year, ahora.month, ahora.day, 23, 59),
      );
      expect(recordatorioHoy.esHoy, isTrue);
      expect(recordatorioHoy.tiempoRestanteTexto, 'Hoy');

      final recordatorioManana = RecordatorioEvaluacion(
        id: '2',
        titulo: 'Quiz 2',
        cursoId: 'c1',
        cursoNombre: 'Curso 1',
        fecha: ahora.add(const Duration(days: 1)),
      );
      expect(recordatorioManana.esManana, isTrue);
      expect(recordatorioManana.tiempoRestanteTexto, 'Mañana');

      final recordatorioFuturo = RecordatorioEvaluacion(
        id: '3',
        titulo: 'Proyecto',
        cursoId: 'c1',
        cursoNombre: 'Curso 1',
        fecha: ahora.add(const Duration(days: 5)),
      );
      expect(recordatorioFuturo.diasRestantes, greaterThanOrEqualTo(4));
      expect(recordatorioFuturo.estaVencido, isFalse);

      final recordatorioPasado = RecordatorioEvaluacion(
        id: '4',
        titulo: 'Práctica 1',
        cursoId: 'c1',
        cursoNombre: 'Curso 1',
        fecha: ahora.subtract(const Duration(days: 3)),
      );
      expect(recordatorioPasado.estaVencido, isTrue);
      expect(recordatorioPasado.tiempoRestanteTexto, contains('Venció'));

      final recordatorioCompletado = recordatorioPasado.copyWith(completado: true);
      expect(recordatorioCompletado.estaVencido, isFalse);
      expect(recordatorioCompletado.tiempoRestanteTexto, 'Rendida');
    });

    test('Inmutabilidad y copyWith', () {
      final rec = RecordatorioEvaluacion(
        id: 'rec_1',
        titulo: 'Parcial',
        cursoId: 'c1',
        cursoNombre: 'Móviles',
        fecha: DateTime(2026, 12, 1),
      );

      final editado = rec.copyWith(
        titulo: 'Parcial Reagendado',
        fecha: DateTime(2026, 12, 5),
        completado: true,
      );

      expect(editado.id, 'rec_1');
      expect(editado.titulo, 'Parcial Reagendado');
      expect(editado.fecha, DateTime(2026, 12, 5));
      expect(editado.completado, isTrue);
      expect(rec.titulo, 'Parcial'); // Inmutable
    });

    test('Formato de fecha amigable fechaFormateada', () {
      final rec = RecordatorioEvaluacion(
        id: '1',
        titulo: 'Examen',
        cursoId: 'c1',
        cursoNombre: 'Móviles',
        fecha: DateTime(2026, 11, 15, 8, 5),
      );

      expect(rec.fechaFormateada, '15 Nov, 08:05');
    });
  });

  group('H26 - Servicio RecordatoriosService (Modo local/fallback)', () {
    final service = RecordatoriosService();

    setUp(() {
      RecordatoriosService.limpiarMemoriaParaPruebas();
    });

    test('Creación, listado y ordenamiento cronológico', () async {
      final ahora = DateTime.now();

      final id1 = await service.crearRecordatorio(
        uid: '',
        titulo: 'Evaluación Tardía',
        cursoId: 'c1',
        cursoNombre: 'Curso A',
        fecha: ahora.add(const Duration(days: 10)),
      );

      final id2 = await service.crearRecordatorio(
        uid: '',
        titulo: 'Evaluación Temprana',
        cursoId: 'c2',
        cursoNombre: 'Curso B',
        fecha: ahora.add(const Duration(days: 2)),
      );

      final streamList = await service.obtenerRecordatorios('').first;
      expect(streamList.any((r) => r.id == id1), isTrue);
      expect(streamList.any((r) => r.id == id2), isTrue);

      // Verificamos que la temprana esté antes que la tardía
      final idx1 = streamList.indexWhere((r) => r.id == id1);
      final idx2 = streamList.indexWhere((r) => r.id == id2);
      expect(idx2, lessThan(idx1));
    });

    test('Actualización y cambio de estado a completado', () async {
      final id = await service.crearRecordatorio(
        uid: '',
        titulo: 'Por Actualizar',
        cursoId: 'c1',
        cursoNombre: 'Curso A',
        fecha: DateTime.now().add(const Duration(days: 1)),
      );

      await service.actualizarRecordatorio(
        uid: '',
        id: id,
        titulo: 'Título Actualizado',
        descripcion: 'Nueva descripción',
      );

      var lista = await service.obtenerRecordatorios('').first;
      var item = lista.firstWhere((r) => r.id == id);
      expect(item.titulo, 'Título Actualizado');
      expect(item.descripcion, 'Nueva descripción');
      expect(item.completado, isFalse);

      await service.cambiarEstadoCompletado('', id, true);
      lista = await service.obtenerRecordatorios('').first;
      item = lista.firstWhere((r) => r.id == id);
      expect(item.completado, isTrue);
    });

    test('Eliminación de recordatorio', () async {
      final id = await service.crearRecordatorio(
        uid: '',
        titulo: 'Para Borrar',
        cursoId: 'c1',
        cursoNombre: 'Curso A',
        fecha: DateTime.now().add(const Duration(days: 1)),
      );

      await service.eliminarRecordatorio('', id);
      final lista = await service.obtenerRecordatorios('').first;
      expect(lista.any((r) => r.id == id), isFalse);
    });
  });

  group('H26 - Interfaz de Usuario RecordatoriosScreen', () {
    setUp(() {
      RecordatoriosService.limpiarMemoriaParaPruebas();
    });

    testWidgets('Renderiza filtros y estado vacío inicial', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RecordatoriosScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Recordatorios de evaluaciones'), findsOneWidget);
      expect(find.text('Pendientes'), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Rendidas'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('¡Estás al día!'), findsOneWidget);
    });
  });
}
