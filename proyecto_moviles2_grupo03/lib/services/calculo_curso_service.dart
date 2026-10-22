import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/curso.dart';
import '../models/nota.dart';
import '../models/tipo_evaluacion.dart';
import '../models/unidad.dart';
import 'calculos_multinivel.dart';

class ResumenCiclo {
  final int cantidadCursos;
  final int cursosConNotas;
  final int totalCreditos;
  final int creditosEvaluados;
  final double? promedio;

  const ResumenCiclo({
    required this.cantidadCursos,
    required this.cursosConNotas,
    this.totalCreditos = 0,
    this.creditosEvaluados = 0,
    required this.promedio,
  });
}

class CalculoCursoService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _cursosRef(String uid) {
    return _firestore.collection('usuarios').doc(uid).collection('cursos');
  }

  /// Calcula las notas de todas las unidades del curso.
  Future<ResultadoCalculoCurso> obtenerCalculoCurso(
    String uid,
    String cursoId,
  ) async {
    final unidadesSnapshot =
        await _cursosRef(uid).doc(cursoId).collection('unidades').get();

    final estructurasUnidad = await Future.wait(
      unidadesSnapshot.docs.map((uDoc) async {
        final unidad = Unidad.fromMap(uDoc.id, uDoc.data());

        final tiposSnapshot =
            await uDoc.reference.collection('tiposEvaluacion').get();

        final estructurasTipos = await Future.wait(
          tiposSnapshot.docs.map((tDoc) async {
            final tipo = TipoEvaluacion.fromMap(tDoc.id, tDoc.data());

            final notasSnapshot =
                await tDoc.reference.collection('notas').get();

            final notas = notasSnapshot.docs
                .map((nDoc) => Nota.fromMap(nDoc.id, nDoc.data()))
                .toList();

            return EstructuraTipoEvaluacion(
              tipo: tipo,
              notas: notas,
            );
          }),
        );

        return EstructuraUnidad(
          unidad: unidad,
          tipos: estructurasTipos,
        );
      }),
    );

    return CalculosMultinivel.calcular(estructurasUnidad);
  }

  /// Obtiene los pesos porcentuales de las unidades para H16.
  Future<Map<String, double>> obtenerPesosUnidades(
    String uid,
    String cursoId,
  ) async {
    final snapshot =
        await _cursosRef(uid).doc(cursoId).collection('unidades').get();

    return {
      for (final doc in snapshot.docs)
        doc.id: (doc.data()['porcentaje'] as num?)?.toDouble() ?? 0.0,
    };
  }

  /// Calcula los resultados de varios cursos en paralelo.
  Future<Map<String, ResultadoCalculoCurso>> obtenerCalculosCursos(
    String uid,
    List<Curso> cursos,
  ) async {
    final resultados = await Future.wait(
      cursos.map((curso) => obtenerCalculoCurso(uid, curso.id)),
    );

    return {
      for (var i = 0; i < cursos.length; i++)
        cursos[i].id: resultados[i],
    };
  }

  /// Promedio ponderado por créditos de los cursos que tienen notas (H21).
  /// Si un curso no tiene créditos especificados o es <= 0, toma 3 por defecto.
  /// Retorna null si no hay cursos con notas.
  static double? promedioPonderadoCiclo({
    required List<Curso> cursos,
    required Map<String, ResultadoCalculoCurso> resultados,
  }) {
    double sumaPonderada = 0.0;
    int sumaCreditos = 0;

    for (final curso in cursos) {
      final res = resultados[curso.id];
      final nota = res?.notaActual;
      if (nota != null) {
        final cr = curso.creditos > 0 ? curso.creditos : 3;
        sumaPonderada += (nota * cr);
        sumaCreditos += cr;
      }
    }

    if (sumaCreditos == 0) return null;
    return CalculosMultinivel.redondearUnDecimal(sumaPonderada / sumaCreditos);
  }

  /// Promedio de las notas actuales de los cursos que tienen notas (aritmético simple).
  static double? promedioDeCursos(
    Iterable<ResultadoCalculoCurso> resultados,
  ) {
    final notas = resultados
        .map((resultado) => resultado.notaActual)
        .whereType<double>()
        .toList();

    if (notas.isEmpty) return null;

    final suma = notas.fold<double>(
      0.0,
      (acumulado, nota) => acumulado + nota,
    );

    return CalculosMultinivel.redondearUnDecimal(suma / notas.length);
  }

  /// Obtiene el resumen de un ciclo con promedio ponderado por créditos.
  Future<ResumenCiclo> obtenerResumenCiclo(
    String uid,
    String cicloId,
  ) async {
    final cursosSnapshot =
        await _cursosRef(uid).where('cicloId', isEqualTo: cicloId).get();

    final cursos = cursosSnapshot.docs
        .map((doc) => Curso.fromMap(doc.id, doc.data()))
        .toList();

    final resultados = await obtenerCalculosCursos(uid, cursos);

    final totalCreditos = cursos.fold<int>(
      0,
      (acc, c) => acc + (c.creditos > 0 ? c.creditos : 3),
    );
    final creditosEvaluados = cursos
        .where((c) => resultados[c.id]?.notaActual != null)
        .fold<int>(
          0,
          (acc, c) => acc + (c.creditos > 0 ? c.creditos : 3),
        );

    return ResumenCiclo(
      cantidadCursos: cursos.length,
      cursosConNotas:
          resultados.values.where((r) => r.notaActual != null).length,
      totalCreditos: totalCreditos,
      creditosEvaluados: creditosEvaluados,
      promedio: promedioPonderadoCiclo(
        cursos: cursos,
        resultados: resultados,
      ),
    );
  }
}