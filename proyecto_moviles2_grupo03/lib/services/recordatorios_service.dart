import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recordatorio_evaluacion.dart';

/// Servicio para la gestión persistente del CRUD de recordatorios de evaluaciones (H26).
///
/// Gestiona la colección `usuarios/{uid}/recordatorios` en Firestore y ofrece
/// persistencia en memoria como fallback para sesiones sin cuenta o pruebas.
class RecordatoriosService {
  final FirebaseFirestore? _firestore;

  static int _idContador = 0;
  // Fallback en memoria para sesiones en modo sin cuenta o pruebas sin Firebase
  static final List<RecordatorioEvaluacion> _recordatoriosMemoria = [];
  static final StreamController<List<RecordatorioEvaluacion>> _memoriaController =
      StreamController<List<RecordatorioEvaluacion>>.broadcast();

  RecordatoriosService({FirebaseFirestore? firestore})
      : _firestore = firestore;

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

  /// Registra un nuevo recordatorio de evaluación.
  Future<String> crearRecordatorio({
    required String uid,
    required String titulo,
    required String cursoId,
    required String cursoNombre,
    String? unidadId,
    String? unidadNombre,
    required DateTime fecha,
    String descripcion = '',
  }) async {
    if (uid.isEmpty) {
      final id =
          'local_${DateTime.now().microsecondsSinceEpoch}_${++_idContador}';
      final rec = RecordatorioEvaluacion(
        id: id,
        titulo: titulo.trim(),
        cursoId: cursoId,
        cursoNombre: cursoNombre.trim(),
        unidadId: unidadId,
        unidadNombre: unidadNombre,
        fecha: fecha,
        descripcion: descripcion.trim(),
        completado: false,
      );
      _recordatoriosMemoria.add(rec);
      _memoriaController.add(List.from(_recordatoriosMemoria));
      return id;
    }

    final docRef = _col(uid).doc();
    final rec = RecordatorioEvaluacion(
      id: docRef.id,
      titulo: titulo.trim(),
      cursoId: cursoId,
      cursoNombre: cursoNombre.trim(),
      unidadId: unidadId,
      unidadNombre: unidadNombre,
      fecha: fecha,
      descripcion: descripcion.trim(),
      completado: false,
    );

    await docRef.set(rec.toMap());
    return docRef.id;
  }

  /// Actualiza los datos de un recordatorio existente.
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
  }) async {
    if (uid.isEmpty) {
      final idx = _recordatoriosMemoria.indexWhere((r) => r.id == id);
      if (idx != -1) {
        final actual = _recordatoriosMemoria[idx];
        _recordatoriosMemoria[idx] = actual.copyWith(
          titulo: titulo,
          cursoId: cursoId,
          cursoNombre: cursoNombre,
          unidadId: unidadId,
          unidadNombre: unidadNombre,
          fecha: fecha,
          descripcion: descripcion,
          completado: completado,
        );
        _memoriaController.add(List.from(_recordatoriosMemoria));
      }
      return;
    }

    final data = <String, dynamic>{};
    if (titulo != null) data['titulo'] = titulo.trim();
    if (cursoId != null) data['cursoId'] = cursoId;
    if (cursoNombre != null) data['cursoNombre'] = cursoNombre.trim();
    if (unidadId != null) data['unidadId'] = unidadId;
    if (unidadNombre != null) data['unidadNombre'] = unidadNombre;
    if (fecha != null) data['fecha'] = Timestamp.fromDate(fecha);
    if (descripcion != null) data['descripcion'] = descripcion.trim();
    if (completado != null) data['completado'] = completado;

    if (data.isNotEmpty) {
      await _col(uid).doc(id).update(data);
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

  /// Elimina un recordatorio de evaluación.
  Future<void> eliminarRecordatorio(String uid, String id) async {
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
