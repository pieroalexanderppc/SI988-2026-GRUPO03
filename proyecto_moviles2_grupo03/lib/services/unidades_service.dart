import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/unidad.dart';

class UnidadesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _unidadesRef(
    String uid,
    String cursoId,
  ) {
    return _firestore
        .collection('usuarios')
        .doc(uid)
        .collection('cursos')
        .doc(cursoId)
        .collection('unidades');
  }

  Stream<List<Unidad>> obtenerUnidades(
    String uid,
    String cursoId,
  ) {
    return _unidadesRef(uid, cursoId).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Unidad.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  Future<void> crearUnidad(
    String uid,
    String cursoId,
    String nombre,
    double porcentaje,
  ) async {
    final ref = _unidadesRef(uid, cursoId).doc();

    final unidad = Unidad(
      id: ref.id,
      nombre: nombre.trim(),
      cursoId: cursoId,
      porcentaje: porcentaje,
    );

    await ref.set(unidad.toMap());
  }

  Future<void> actualizarUnidad(
    String uid,
    String cursoId,
    Unidad unidad,
    String nombre,
    double porcentaje,
  ) async {
    await _unidadesRef(uid, cursoId).doc(unidad.id).update({
      'nombre': nombre.trim(),
      'porcentaje': porcentaje,
    });
  }

  Future<void> eliminarUnidad(
    String uid,
    String cursoId,
    String unidadId,
  ) async {
    await _unidadesRef(uid, cursoId).doc(unidadId).delete();
  }
}