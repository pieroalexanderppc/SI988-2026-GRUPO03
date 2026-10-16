import '../models/nota.dart';
import '../models/tipo_evaluacion.dart';

/// Funciones puras de cálculo para tipos de evaluación y notas en una unidad académica.
class CalculosEvaluaciones {
  /// Calcula el promedio simple de una lista de notas dentro de un tipo de evaluación.
  /// Retorna `null` si no hay notas registradas.
  static double? calcularPromedioTipo(List<Nota> notas) {
    if (notas.isEmpty) return null;
    final suma = notas.fold<double>(0.0, (acc, n) => acc + n.valor);
    return suma / notas.length;
  }

  /// Calcula la suma total de los porcentajes de los tipos de evaluación.
  static double calcularTotalPorcentaje(List<TipoEvaluacion> tipos) {
    return tipos.fold<double>(0.0, (acc, t) => acc + t.porcentaje);
  }

  /// Valida si los porcentajes de los tipos de evaluación suman 100% (tolerancia de 0.1).
  static bool validarSumaPorcentajes(List<TipoEvaluacion> tipos) {
    if (tipos.isEmpty) return false;
    final total = calcularTotalPorcentaje(tipos);
    return (total - 100.0).abs() <= 0.1;
  }

  /// Calcula la nota final ponderada de la unidad a partir de los tipos de evaluación
  /// y sus notas asociadas.
  /// Cada tipo con notas aporta: `promedioTipo * (tipo.porcentaje / 100)`.
  /// Si ningún tipo tiene notas registradas, retorna `null`.
  static double? calcularNotaUnidad(
    List<TipoEvaluacion> tipos,
    Map<String, List<Nota>> notasPorTipo,
  ) {
    if (tipos.isEmpty) return null;

    double sumaPonderada = 0.0;
    bool tieneAlMenosUnaNota = false;

    for (final tipo in tipos) {
      final notas = notasPorTipo[tipo.id] ?? [];
      final promedioTipo = calcularPromedioTipo(notas);
      if (promedioTipo != null) {
        tieneAlMenosUnaNota = true;
        sumaPonderada += promedioTipo * (tipo.porcentaje / 100.0);
      }
    }

    if (!tieneAlMenosUnaNota) return null;
    return sumaPonderada;
  }

  /// Promedio de lo evaluado en la unidad (escala 0-20): no cuenta como 0
  /// los tipos que aun no tienen notas. Retorna `null` si no hay notas.
  /// Si todos los tipos tienen notas y suman 100 %, coincide con [calcularNotaUnidad].
  static double? calcularPromedioParcialUnidad(
    List<TipoEvaluacion> tipos,
    Map<String, List<Nota>> notasPorTipo,
  ) {
    final nota = calcularNotaUnidad(tipos, notasPorTipo);
    if (nota == null) return null;
    final evaluado = tipos
        .where((t) => (notasPorTipo[t.id] ?? []).isNotEmpty)
        .fold<double>(0.0, (acc, t) => acc + t.porcentaje);
    if (evaluado <= 0) return null;
    return nota / (evaluado / 100.0);
  }

  /// Determina si una nota es aprobatoria según el estándar peruano (>= 10.5).
  static bool esAprobado(double nota) {
    return nota >= 10.5;
  }
}
