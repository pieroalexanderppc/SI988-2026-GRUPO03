import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_moviles2_grupo03/models/recordatorio_evaluacion.dart';
import 'package:proyecto_moviles2_grupo03/services/notificaciones_service.dart';
import 'package:proyecto_moviles2_grupo03/services/recordatorios_service.dart';

void main() {
  group('H30 - Modelo RecordatorioEvaluacion con Notificaciones', () {
    test('Valores por defecto y propiedades de notificación', () {
      final fecha = DateTime.now().add(const Duration(days: 3));
      final rec = RecordatorioEvaluacion(
        id: 'eval_abc_123',
        titulo: 'Examen de Redes',
        cursoId: 'curso_redes',
        cursoNombre: 'Redes y Comunicaciones',
        fecha: fecha,
      );

      expect(rec.notificar, isTrue);
      expect(rec.antelacionHoras, 24);
      expect(rec.notificacionId, isPositive);
      expect(rec.notificacionIdCorta, isPositive);
      expect(rec.notificacionId, isNot(equals(rec.notificacionIdCorta)));
    });

    test('Serialización y deserialización de atributos de notificación', () {
      final fecha = DateTime(2026, 12, 1, 10, 0);
      final rec = RecordatorioEvaluacion(
        id: 'rec_h30_test',
        titulo: 'Entrega Final Proyecto',
        cursoId: 'c_moviles',
        cursoNombre: 'Soluciones Móviles II',
        fecha: fecha,
        notificar: true,
        antelacionHoras: 12,
      );

      final map = rec.toMap();
      expect(map['notificar'], isTrue);
      expect(map['antelacionHoras'], 12);

      final copia = RecordatorioEvaluacion.fromMap('rec_h30_test', map);
      expect(copia.notificar, isTrue);
      expect(copia.antelacionHoras, 12);

      final modificada = copia.copyWith(notificar: false, antelacionHoras: 2);
      expect(modificada.notificar, isFalse);
      expect(modificada.antelacionHoras, 2);
    });
  });

  group('H30 - NotificacionesService y Planificación de Alarmas', () {
    late NotificacionesService notificaciones;

    setUp(() async {
      notificaciones = NotificacionesService();
      await notificaciones.inicializar();
      notificaciones.limpiarRegistrosParaPruebas();
    });

    test('NotificacionesService es singleton y se inicializa correctamente', () {
      final instancia2 = NotificacionesService();
      expect(identical(notificaciones, instancia2), isTrue);
      expect(notificaciones.estaInicializado, isTrue);
    });

    test('Programa alerta anticipada (24h) y urgente (1h) para examen futuro', () async {
      final fechaFutura = DateTime.now().add(const Duration(days: 3));
      final rec = RecordatorioEvaluacion(
        id: 'rec_futuro_01',
        titulo: 'Examen Parcial',
        cursoId: 'c1',
        cursoNombre: 'Sistemas Operativos',
        fecha: fechaFutura,
        notificar: true,
        antelacionHoras: 24,
      );

      await notificaciones.programarNotificacion(rec);

      expect(notificaciones.registrosPruebas.length, 2);
      final principal = notificaciones.registrosPruebas.first;
      expect(principal['id'], rec.notificacionId);
      expect(principal['payload'], rec.id);
      expect(principal['titulo'], contains('Examen Parcial'));

      final urgente = notificaciones.registrosPruebas.last;
      expect(urgente['id'], rec.notificacionIdCorta);
      expect(urgente['payload'], rec.id);
      expect(urgente['titulo'], contains('1 hora'));
    });

    test('No programa notificaciones si notificar es false o la evaluación está rendida', () async {
      final fechaFutura = DateTime.now().add(const Duration(days: 2));
      final recDesactivada = RecordatorioEvaluacion(
        id: 'rec_no_notif',
        titulo: 'Lectura no evaluada',
        cursoId: 'c1',
        cursoNombre: 'Curso X',
        fecha: fechaFutura,
        notificar: false,
      );

      await notificaciones.programarNotificacion(recDesactivada);
      expect(notificaciones.registrosPruebas, isEmpty);

      final recRendida = RecordatorioEvaluacion(
        id: 'rec_rendida',
        titulo: 'Examen Pasado',
        cursoId: 'c1',
        cursoNombre: 'Curso Y',
        fecha: fechaFutura,
        completado: true,
      );

      await notificaciones.programarNotificacion(recRendida);
      expect(notificaciones.registrosPruebas, isEmpty);
    });

    test('No agenda notificaciones para evaluaciones con fecha pasada', () async {
      final fechaPasada = DateTime.now().subtract(const Duration(days: 1));
      final recPasada = RecordatorioEvaluacion(
        id: 'rec_antigua',
        titulo: 'Control 1',
        cursoId: 'c1',
        cursoNombre: 'Curso Z',
        fecha: fechaPasada,
      );

      await notificaciones.programarNotificacion(recPasada);
      expect(notificaciones.registrosPruebas, isEmpty);
    });

    test('cancelarNotificacion remueve las alertas del registro por su id', () async {
      final fechaFutura = DateTime.now().add(const Duration(days: 4));
      final rec = RecordatorioEvaluacion(
        id: 'rec_cancelar_test',
        titulo: 'Examen Cancelable',
        cursoId: 'c1',
        cursoNombre: 'Curso A',
        fecha: fechaFutura,
      );

      await notificaciones.programarNotificacion(rec);
      expect(notificaciones.registrosPruebas, isNotEmpty);

      await notificaciones.cancelarNotificacion(rec.id);
      expect(notificaciones.registrosPruebas, isEmpty);
    });
  });

  group('H30 - Integración RecordatoriosService con NotificacionesService', () {
    late RecordatoriosService recordatoriosService;
    late NotificacionesService notificacionesService;

    setUp(() async {
      RecordatoriosService.limpiarMemoriaParaPruebas();
      notificacionesService = NotificacionesService();
      await notificacionesService.inicializar();
      notificacionesService.limpiarRegistrosParaPruebas();
      recordatoriosService = RecordatoriosService(
        notificaciones: notificacionesService,
      );
    });

    test('crearRecordatorio agenda automáticamente las notificaciones locales', () async {
      final fecha = DateTime.now().add(const Duration(days: 5));
      final id = await recordatoriosService.crearRecordatorio(
        uid: '', // modo memoria / local
        titulo: 'Examen Integrador',
        cursoId: 'curso_int',
        cursoNombre: 'Taller Integrador',
        fecha: fecha,
        notificar: true,
        antelacionHoras: 24,
      );

      expect(id, isNotEmpty);
      expect(notificacionesService.registrosPruebas, isNotEmpty);
      expect(notificacionesService.registrosPruebas.first['payload'], id);
    });

    test('eliminarRecordatorio cancela las notificaciones asociadas', () async {
      final fecha = DateTime.now().add(const Duration(days: 5));
      final id = await recordatoriosService.crearRecordatorio(
        uid: '',
        titulo: 'Examen a Borrar',
        cursoId: 'c_borrar',
        cursoNombre: 'Curso Borrar',
        fecha: fecha,
      );

      expect(notificacionesService.registrosPruebas, isNotEmpty);

      await recordatoriosService.eliminarRecordatorio('', id);
      expect(notificacionesService.registrosPruebas, isEmpty);
    });

    test('cambiarEstadoCompletado a true cancela las alarmas pendientes', () async {
      final fecha = DateTime.now().add(const Duration(days: 5));
      final id = await recordatoriosService.crearRecordatorio(
        uid: '',
        titulo: 'Examen a Rendir',
        cursoId: 'c_rendir',
        cursoNombre: 'Curso Rendir',
        fecha: fecha,
      );

      expect(notificacionesService.registrosPruebas, isNotEmpty);

      await recordatoriosService.cambiarEstadoCompletado('', id, true);
      expect(notificacionesService.registrosPruebas, isEmpty);
    });
  });
}
