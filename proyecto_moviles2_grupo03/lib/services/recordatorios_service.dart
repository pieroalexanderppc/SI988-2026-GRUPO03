import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recordatorio_evaluacion.dart';
import 'notificaciones_service.dart';

/// Servicio para la gestión persistente del CRUD de recordatorios de evaluaciones (H26),
/// integrado con el sistema de notificaciones locales programadas (H30).
class RecordatoriosService {
  final FirebaseFirestore? _firestore;
  final NotificacionesService _notificaciones;

  static int _idContador = 0;
  // Fallback en memoria para sesiones en modo sin cuenta o pruebas sin Firebase
  static final List<RecordatorioEvaluacion> _recordatoriosMemoria = [];
  static final StreamController<List<RecordatorioEvaluacion>> _memoriaController =
      StreamController<List<RecordatorioEvaluacion>>.broadcast();

  RecordatoriosService({
    FirebaseFirestore? firestore,
    NotificacionesService? notificaciones,
  })  : _firestore = firestore,
        _notificaciones = notificaciones ?? NotificacionesService();

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('usuarios').doc(uid).collection('recordatorios');

  /// Obtiene todos los recordatorios del usuario ordenados por fecha de evaluación.
  Stream<List<RecordatorioEvaluacion>> obtenerRecordatorios(String uid) {
    if (uid.isEmpty) {
      Stream<List<RecordatorioEvaluacion>> streamLocal() async* {
        final inicial = List<RecordatorioEvaluacion>.from(_recordatoriosMemoria);
        inicial.sort((a, b) => a.fecha.compareTo(b.fecha));
        yield inicial;
        yield* _memoriaController.stream.map((list) {
          final copia = List<RecordatorioEvaluacion>.from(list);
          copia.sort((a, b) => a.fecha.compareTo(b.fecha));
          return copia;
        });
      }

      return streamLocal();
    }

    return _col(uid)
        .orderBy('fecha', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RecordatorioEvaluacion.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Obtiene los recordatorios de un curso específico.
  Stream<List<RecordatorioEvaluacion>> obtenerRecordatoriosPorCurso(
    String uid,
    String cursoId,
  ) {
    if (uid.isEmpty) {
      return obtenerRecordatorios(uid).map(
        (list) => list.where((r) => r.cursoId == cursoId).toList(),
      );
    }

    return _col(uid)
        .where('cursoId', isEqualTo: cursoId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => RecordatorioEvaluacion.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => a.fecha.compareTo(b.fecha));
      return list;
    });
  }

  /// Registra un nuevo recordatorio de evaluación y agenda su notificación local si aplica.
  Future<String> crearRecordatorio({
    required String uid,
    required String titulo,
    required String cursoId,
    required String cursoNombre,
    String? unidadId,
    String? unidadNombre,
    required DateTime fecha,
    String descripcion = '',
    bool notificar = true,
    int antelacionHoras = 24,
  }) async {
    RecordatorioEvaluacion rec;
    String idCreado;

    if (uid.isEmpty) {
      idCreado =
          'local_${DateTime.now().microsecondsSinceEpoch}_${++_idContador}';
      rec = RecordatorioEvaluacion(
        id: idCreado,
        titulo: titulo.trim(),
        cursoId: cursoId,
        cursoNombre: cursoNombre.trim(),
        unidadId: unidadId,
        unidadNombre: unidadNombre,
        fecha: fecha,
        descripcion: descripcion.trim(),
        completado: false,
        notificar: notificar,
        antelacionHoras: antelacionHoras,
      );
      _recordatoriosMemoria.add(rec);
      _memoriaController.add(List.from(_recordatoriosMemoria));
    } else {
      final docRef = _col(uid).doc();
      idCreado = docRef.id;
      rec = RecordatorioEvaluacion(
        id: idCreado,
        titulo: titulo.trim(),
        cursoId: cursoId,
        cursoNombre: cursoNombre.trim(),
        unidadId: unidadId,
        unidadNombre: unidadNombre,
        fecha: fecha,
        descripcion: descripcion.trim(),
        completado: false,
        notificar: notificar,
        antelacionHoras: antelacionHoras,
      );
      await docRef.set(rec.toMap());
    }

    if (notificar) {
      await _notificaciones.programarNotificacion(rec);
    }

    return idCreado;
  }

  /// Actualiza los datos de un recordatorio existente y reprograma sus notificaciones.
  Future<void> actualizarRecordatorio({
    required String uid,
    required String id,
    String? titulo,
    String? cursoId,
    String? cursoNombre,
    String? unidadId,
    String? unidadNombre,
    DateTime? fecha,
    String? descripcion,
    bool? completado,
    bool? notificar,
    int? antelacionHoras,
  }) async {
    RecordatorioEvaluacion? actualizado;

    if (uid.isEmpty) {
      final idx = _recordatoriosMemoria.indexWhere((r) => r.id == id);
      if (idx != -1) {
        final actual = _recordatoriosMemoria[idx];
        actualizado = actual.copyWith(
          titulo: titulo,
          cursoId: cursoId,
          cursoNombre: cursoNombre,
          unidadId: unidadId,
          unidadNombre: unidadNombre,
          fecha: fecha,
          descripcion: descripcion,
          completado: completado,
          notificar: notificar,
          antelacionHoras: antelacionHoras,
        );
        _recordatoriosMemoria[idx] = actualizado;
        _memoriaController.add(List.from(_recordatoriosMemoria));
      }
    } else {
      final data = <String, dynamic>{};
      if (titulo != null) data['titulo'] = titulo.trim();
      if (cursoId != null) data['cursoId'] = cursoId;
      if (cursoNombre != null) data['cursoNombre'] = cursoNombre.trim();
      if (unidadId != null) data['unidadId'] = unidadId;
      if (unidadNombre != null) data['unidadNombre'] = unidadNombre;
      if (fecha != null) data['fecha'] = Timestamp.fromDate(fecha);
      if (descripcion != null) data['descripcion'] = descripcion.trim();
      if (completado != null) data['completado'] = completado;
      if (notificar != null) data['notificar'] = notificar;
      if (antelacionHoras != null) data['antelacionHoras'] = antelacionHoras;

      if (data.isNotEmpty) {
        await _col(uid).doc(id).update(data);
        final doc = await _col(uid).doc(id).get();
        if (doc.exists && doc.data() != null) {
          actualizado = RecordatorioEvaluacion.fromMap(doc.id, doc.data()!);
        }
      }
    }

    // Reprogramar o cancelar alarma según el estado actualizado
    if (actualizado != null) {
      if (actualizado.completado || !actualizado.notificar) {
        await _notificaciones.cancelarNotificacion(id);
      } else {
        await _notificaciones.programarNotificacion(actualizado);
      }
    }
  }

  /// Marca o desmarca un recordatorio como completado/rendido.
  Future<void> cambiarEstadoCompletado(
    String uid,
    String id,
    bool completado,
  ) async {
    await actualizarRecordatorio(
      uid: uid,
      id: id,
      completado: completado,
    );
  }

  /// Elimina un recordatorio de evaluación y cancela sus alarmas.
  Future<void> eliminarRecordatorio(String uid, String id) async {
    await _notificaciones.cancelarNotificacion(id);

    if (uid.isEmpty) {
      _recordatoriosMemoria.removeWhere((r) => r.id == id);
      _memoriaController.add(List.from(_recordatoriosMemoria));
      return;
    }

    await _col(uid).doc(id).delete();
  }

  /// Limpia la memoria local (útil para pruebas unitarias y de widgets).
  static void limpiarMemoriaParaPruebas() {
    _recordatoriosMemoria.clear();
    _memoriaController.add([]);
  }
}
