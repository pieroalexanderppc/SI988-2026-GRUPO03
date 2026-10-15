import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/nota.dart';
import '../models/tipo_evaluacion.dart';

class EvaluacionesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _tiposRef(
    String uid,
    String cursoId,
    String unidadId,
  ) {
    return _firestore
        .collection('usuarios')
        .doc(uid)
        .collection('cursos')
        .doc(cursoId)
        .collection('unidades')
        .doc(unidadId)
        .collection('tiposEvaluacion');
  }

  CollectionReference<Map<String, dynamic>> _notasRef(
    String uid,
    String cursoId,
    String unidadId,
    String tipoId,
  ) {
    return _tiposRef(uid, cursoId, unidadId)
        .doc(tipoId)
        .collection('notas');
  }

  // --- CRUD TIPOS DE EVALUACIÓN ---

  Stream<List<TipoEvaluacion>> obtenerTiposEvaluacion(
    String uid,
    String cursoId,
    String unidadId,
  ) {
    return _tiposRef(uid, cursoId, unidadId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => TipoEvaluacion.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> crearTipoEvaluacion(
    String uid,
    String cursoId,
    String unidadId,
    String nombre,
    double porcentaje,
  ) async {
    final ref = _tiposRef(uid, cursoId, unidadId).doc();
    final tipo = TipoEvaluacion(
      id: ref.id,
      nombre: nombre.trim(),
      porcentaje: porcentaje,
    );
    await ref.set(tipo.toMap());
  }

  Future<void> actualizarTipoEvaluacion(
    String uid,
    String cursoId,
    String unidadId,
    TipoEvaluacion tipo,
    String nombre,
    double porcentaje,
  ) async {
    await _tiposRef(uid, cursoId, unidadId).doc(tipo.id).update({
      'nombre': nombre.trim(),
      'porcentaje': porcentaje,
    });
  }

  Future<void> eliminarTipoEvaluacion(
    String uid,
    String cursoId,
    String unidadId,
    String tipoId,
  ) async {
    // Eliminar notas anidadas en la subcolección
    final notasSnapshot = await _notasRef(uid, cursoId, unidadId, tipoId).get();
    final batch = _firestore.batch();
    for (final doc in notasSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_tiposRef(uid, cursoId, unidadId).doc(tipoId));
    await batch.commit();
  }

  // --- CRUD NOTAS ---

  Stream<List<Nota>> obtenerNotas(
    String uid,
    String cursoId,
    String unidadId,
    String tipoId,
  ) {
    return _notasRef(uid, cursoId, unidadId, tipoId)
        .orderBy('fecha', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Nota.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> crearNota(
    String uid,
    String cursoId,
    String unidadId,
    String tipoId,
    double valor, {
    DateTime? fecha,
  }) async {
    final ref = _notasRef(uid, cursoId, unidadId, tipoId).doc();
    final nota = Nota(
      id: ref.id,
      valor: valor,
      fecha: fecha ?? DateTime.now(),
      tipoEvaluacionId: tipoId,
    );
    await ref.set(nota.toMap());
  }

  Future<void> actualizarNota(
    String uid,
    String cursoId,
    String unidadId,
    String tipoId,
    String notaId,
    double valor, {
    DateTime? fecha,
  }) async {
    final Map<String, dynamic> data = {'valor': valor};
    if (fecha != null) {
      data['fecha'] = Timestamp.fromDate(fecha);
    }
    await _notasRef(uid, cursoId, unidadId, tipoId).doc(notaId).update(data);
  }

  Future<void> eliminarNota(
    String uid,
    String cursoId,
    String unidadId,
    String tipoId,
    String notaId,
  ) async {
    await _notasRef(uid, cursoId, unidadId, tipoId).doc(notaId).delete();
  }
}
