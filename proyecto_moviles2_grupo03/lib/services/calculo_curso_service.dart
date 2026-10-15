import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/nota.dart';
import '../models/tipo_evaluacion.dart';
import '../models/unidad.dart';
import 'calculos_multinivel.dart';

class CalculoCursoService {
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

  /// Carga la jerarquía completa del curso (Unidades -> Tipos -> Notas)
  /// y calcula el resultado multinivel del curso.
  Future<ResultadoCalculoCurso> obtenerCalculoCurso(
    String uid,
    String cursoId,
  ) async {
    final unidadesSnapshot = await _unidadesRef(uid, cursoId).get();

    final List<EstructuraUnidad> estructurasUnidad = [];

    for (final uDoc in unidadesSnapshot.docs) {
      final unidad = Unidad.fromMap(uDoc.id, uDoc.data());

      final tiposSnapshot = await uDoc.reference
          .collection('tiposEvaluacion')
          .get();

      final List<EstructuraTipoEvaluacion> estructurasTipos = [];

      for (final tDoc in tiposSnapshot.docs) {
        final tipo = TipoEvaluacion.fromMap(tDoc.id, tDoc.data());

        final notasSnapshot = await tDoc.reference
            .collection('notas')
            .get();

        final notas = notasSnapshot.docs
            .map((nDoc) => Nota.fromMap(nDoc.id, nDoc.data()))
            .toList();

        estructurasTipos.add(
          EstructuraTipoEvaluacion(
            tipo: tipo,
            notas: notas,
          ),
        );
      }

      estructurasUnidad.add(
        EstructuraUnidad(
          unidad: unidad,
          tipos: estructurasTipos,
        ),
      );
    }

    return CalculosMultinivel.calcular(estructurasUnidad);
  }

  /// Escucha en tiempo real la colección de unidades y dispara el cálculo multinivel.
  Stream<ResultadoCalculoCurso> escucharCalculoCurso(
    String uid,
    String cursoId,
  ) {
    return _unidadesRef(uid, cursoId).snapshots().asyncMap((_) async {
      return await obtenerCalculoCurso(uid, cursoId);
    });
  }
}
