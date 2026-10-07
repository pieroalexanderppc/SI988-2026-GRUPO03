import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/curso.dart';

class CursosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Curso>> obtenerCursos(String uid, String cicloId) {
    return _firestore
        .collection('usuarios')
        .doc(uid)
        .collection('cursos')
        .where('cicloId', isEqualTo: cicloId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Curso.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> crearCurso(
    String uid,
    String cicloId,
    String nombre,
  ) async {
    final ref = _firestore
        .collection('usuarios')
        .doc(uid)
        .collection('cursos')
        .doc();

    final curso = Curso(
      id: ref.id,
      nombre: nombre.trim(),
      cicloId: cicloId,
    );

    await ref.set(curso.toMap());
  }

  Future<void> actualizarCurso(
    String uid,
    Curso curso,
    String nombre,
  ) async {
    await _firestore
        .collection('usuarios')
        .doc(uid)
        .collection('cursos')
        .doc(curso.id)
        .update({
      'nombre': nombre.trim(),
    });
  }

  Future<void> eliminarCurso(
    String uid,
    String cursoId,
  ) async {
    await _firestore
        .collection('usuarios')
        .doc(uid)
        .collection('cursos')
        .doc(cursoId)
        .delete();
  }
}