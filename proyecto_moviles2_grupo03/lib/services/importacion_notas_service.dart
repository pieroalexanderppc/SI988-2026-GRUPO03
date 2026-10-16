import 'package:cloud_firestore/cloud_firestore.dart';

import 'borrado_cascada.dart';
import 'lector_reporte_notas.dart';

/// H19 - Guarda un reporte leido por la camara en la estructura existente:
/// curso -> unidades -> tipos de evaluacion -> notas.
///
/// Cada criterio del portal se guarda como un tipo de evaluacion (nombre =
/// descripcion, porcentaje = Peso C.) con una nota (nombre = "Evaluacion 01").
/// Los criterios sin nota se guardan como tipos sin notas (pendientes).
class ImportacionNotasService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _cursosRef(String uid) =>
      _firestore.collection('usuarios').doc(uid).collection('cursos');

  /// Normaliza un nombre para comparar cursos (sin tildes, mayusculas ni espacios extra).
  static String normalizar(String nombre) => nombre
      .toLowerCase()
      .replaceAll(RegExp('[áà]'), 'a')
      .replaceAll(RegExp('[éè]'), 'e')
      .replaceAll(RegExp('[íì]'), 'i')
      .replaceAll(RegExp('[óò]'), 'o')
      .replaceAll(RegExp('[úù]'), 'u')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Busca en el ciclo un curso con el mismo nombre (para no duplicarlo).
  Future<({String id, String nombre})?> buscarCursoExistente(
    String uid,
    String cicloId,
    String nombre,
  ) async {
    final snapshot = await _cursosRef(uid).where('cicloId', isEqualTo: cicloId).get();
    final buscado = normalizar(nombre);
    for (final doc in snapshot.docs) {
      final n = (doc.data()['nombre'] ?? '') as String;
      if (normalizar(n) == buscado) return (id: doc.id, nombre: n);
    }
    return null;
  }

  /// Guarda el reporte y devuelve el id del curso.
  /// Si [reemplazarCursoId] no es null, se reemplazan las unidades de ese curso.
  Future<String> guardar({
    required String uid,
    required String cicloId,
    required String nombreCurso,
    required List<UnidadDetectada> unidades,
    String? reemplazarCursoId,
  }) async {
    final DocumentReference<Map<String, dynamic>> cursoRef;
    if (reemplazarCursoId != null) {
      cursoRef = _cursosRef(uid).doc(reemplazarCursoId);
      final anteriores = await cursoRef.collection('unidades').get();
      await Future.wait(anteriores.docs.map((u) => BorradoCascada.unidad(u.reference)));
    } else {
      cursoRef = _cursosRef(uid).doc();
    }

    final batch = _firestore.batch();
    batch.set(cursoRef, {'nombre': nombreCurso.trim(), 'cicloId': cicloId}, SetOptions(merge: true));

    final ahora = DateTime.now();
    for (final unidad in unidades) {
      final unidadRef = cursoRef.collection('unidades').doc();
      batch.set(unidadRef, {
        'nombre': unidad.nombre.trim(),
        'cursoId': cursoRef.id,
        'porcentaje': unidad.peso ?? 0,
      });

      for (var i = 0; i < unidad.criterios.length; i++) {
        final c = unidad.criterios[i];
        // Ids con el orden del reporte: Firestore ordena por id por defecto.
        final tipoRef = unidadRef.collection('tiposEvaluacion').doc('${(i + 1).toString().padLeft(2, '0')}_${_idAleatorio()}');
        batch.set(tipoRef, {
          'nombre': c.descripcion.trim().isEmpty ? c.nombre : c.descripcion.trim(),
          'porcentaje': c.peso ?? 0,
        });
        if (c.nota != null) {
          final notaRef = tipoRef.collection('notas').doc();
          batch.set(notaRef, {
            'valor': c.nota,
            'nombre': c.nombre,
            'fecha': Timestamp.fromDate(ahora),
            'tipoEvaluacionId': tipoRef.id,
          });
        }
      }
    }

    await batch.commit();
    return cursoRef.id;
  }

  String _idAleatorio() => _firestore.collection('_').doc().id;
}
