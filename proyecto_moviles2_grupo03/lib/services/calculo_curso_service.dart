import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/curso.dart';
import '../models/nota.dart';
import '../models/tipo_evaluacion.dart';
import '../models/unidad.dart';
import 'calculos_multinivel.dart';

/// Resumen de un ciclo: cuantos cursos tiene y su promedio.
class ResumenCiclo {
  final int cantidadCursos;
  final int cursosConNotas;

  /// Promedio simple de las notas actuales de los cursos con notas.
  final double? promedio;

  const ResumenCiclo({
    required this.cantidadCursos,
    required this.cursosConNotas,
    required this.promedio,
  });
}

class CalculoCursoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _cursosRef(String uid) {
    return _firestore.collection('usuarios').doc(uid).collection('cursos');
  }

  /// Carga la jerarquía completa del curso (Unidades -> Tipos -> Notas)
  /// y calcula el resultado multinivel del curso.
  /// Las lecturas de cada nivel se hacen en paralelo.
  Future<ResultadoCalculoCurso> obtenerCalculoCurso(
    String uid,
    String cursoId,
  ) async {
    final unidadesSnapshot =
        await _cursosRef(uid).doc(cursoId).collection('unidades').get();

    final estructurasUnidad = await Future.wait(
      unidadesSnapshot.docs.map((uDoc) async {
        final unidad = Unidad.fromMap(uDoc.id, uDoc.data());
        final tiposSnapshot = await uDoc.reference.collection('tiposEvaluacion').get();

        final estructurasTipos = await Future.wait(
          tiposSnapshot.docs.map((tDoc) async {
            final tipo = TipoEvaluacion.fromMap(tDoc.id, tDoc.data());
            final notasSnapshot = await tDoc.reference.collection('notas').get();
            final notas = notasSnapshot.docs
                .map((nDoc) => Nota.fromMap(nDoc.id, nDoc.data()))
                .toList();
            return EstructuraTipoEvaluacion(tipo: tipo, notas: notas);
          }),
        );

        return EstructuraUnidad(unidad: unidad, tipos: estructurasTipos);
      }),
    );

    return CalculosMultinivel.calcular(estructurasUnidad);
  }

  /// Calcula el resultado de varios cursos en paralelo (id -> resultado).
  Future<Map<String, ResultadoCalculoCurso>> obtenerCalculosCursos(
    String uid,
    List<Curso> cursos,
  ) async {
    final resultados = await Future.wait(
      cursos.map((c) => obtenerCalculoCurso(uid, c.id)),
    );
    return {
      for (var i = 0; i < cursos.length; i++) cursos[i].id: resultados[i],
    };
  }

  /// Promedio simple de las notas actuales de los cursos que tienen notas.
  static double? promedioDeCursos(Iterable<ResultadoCalculoCurso> resultados) {
    final notas = resultados.map((r) => r.notaActual).whereType<double>().toList();
    if (notas.isEmpty) return null;
    final suma = notas.fold<double>(0.0, (acc, n) => acc + n);
    return CalculosMultinivel.redondearUnDecimal(suma / notas.length);
  }

  /// Resume un ciclo: cantidad de cursos y promedio del ciclo.
  Future<ResumenCiclo> obtenerResumenCiclo(String uid, String cicloId) async {
    final cursosSnapshot =
        await _cursosRef(uid).where('cicloId', isEqualTo: cicloId).get();
    final cursos = cursosSnapshot.docs
        .map((doc) => Curso.fromMap(doc.id, doc.data()))
        .toList();
    final resultados = await obtenerCalculosCursos(uid, cursos);
    return ResumenCiclo(
      cantidadCursos: cursos.length,
      cursosConNotas: resultados.values.where((r) => r.notaActual != null).length,
      promedio: promedioDeCursos(resultados.values),
    );
  }
}
