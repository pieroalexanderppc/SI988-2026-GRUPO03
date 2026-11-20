import '../models/curso.dart';
import '../services/calculos_multinivel.dart';

/// Preset predefinido de simulación académica para cierre de ciclo (H36).
enum PresetSimulacion {
  /// Asigna a cada asignatura la nota mínima de aprobación (10.5).
  minimoAprobatorio,

  /// Proyecta en base al rendimiento real actual obtenido en lo evaluado.
  realista,

  /// Asigna notas de excelencia (16.0+) con el fin de aspirar al Tercio Superior / Cuadro de Honor.
  metaDistincion,
}

/// Representa una asignatura dentro de la simulación de ciclo (H36).
class ItemSimulacionCurso {
  final String cursoId;
  final String cursoNombre;
  final int creditos;
  final double? notaActual;
  final double porcentajeEvaluado;
  final double notaSimulada;

  const ItemSimulacionCurso({
    required this.cursoId,
    required this.cursoNombre,
    required this.creditos,
    this.notaActual,
    this.porcentajeEvaluado = 0.0,
    required this.notaSimulada,
  });

  int get creditosEfectivos => creditos > 0 ? creditos : 3;

  bool get esAprobado => notaSimulada >= 10.5;

  ItemSimulacionCurso copiarCon({
    double? notaSimulada,
  }) {
    return ItemSimulacionCurso(
      cursoId: cursoId,
      cursoNombre: cursoNombre,
      creditos: creditos,
      notaActual: notaActual,
      porcentajeEvaluado: porcentajeEvaluado,
      notaSimulada: (notaSimulada ?? this.notaSimulada).clamp(0.0, 20.0),
    );
  }
}

/// Resultado integral del cálculo multiescenario de cierre de ciclo (H36).
class ResultadoSimulacionCiclo {
  final double promedioSimulado;
  final int totalCreditos;
  final int creditosAprobados;
  final int creditosDesaprobados;
  final double? ppaHistorico;
  final int creditosHistoricos;
  final double? ppaProyectado;
  final double? impactoPpa;
  final bool esTercioSuperior;
  final double distanciaTercioSuperior;

  const ResultadoSimulacionCiclo({
    required this.promedioSimulado,
    required this.totalCreditos,
    required this.creditosAprobados,
    required this.creditosDesaprobados,
    this.ppaHistorico,
    this.creditosHistoricos = 0,
    this.ppaProyectado,
    this.impactoPpa,
    required this.esTercioSuperior,
    required this.distanciaTercioSuperior,
  });

  double get porcentajeCreditosAprobados =>
      totalCreditos > 0 ? (creditosAprobados / totalCreditos) * 100 : 0.0;

  bool get cicloAprobado => promedioSimulado >= 10.5;
}

/// Motor matemático para proyecciones y simulaciones multiescenario de ciclo (H36).
class CalculadoraSimulacionCicloService {
  /// Umbral institucional estándar de Tercio Superior en la Universidad Privada de Tacna (UPT).
  static const double umbralTercioSuperiorDefault = 15.0;

  /// Inicializa los items de simulación a partir de los cursos y resultados actuales de Firestore.
  static List<ItemSimulacionCurso> inicializarDesdeCursos({
    required List<Curso> cursos,
    required Map<String, ResultadoCalculoCurso> resultados,
  }) {
    return cursos.map((curso) {
      final res = resultados[curso.id];
      final notaActual = res?.notaActual;
      final pctEvaluado = res?.porcentajeEvaluado ?? 0.0;

      // Por defecto la nota simulada inicial es la actual si existe, o 11.0
      final inicial = notaActual != null
          ? CalculosMultinivel.redondearUnDecimal(notaActual)
          : 11.0;

      return ItemSimulacionCurso(
        cursoId: curso.id,
        cursoNombre: curso.nombre,
        creditos: curso.creditosEfectivos,
        notaActual: notaActual,
        porcentajeEvaluado: pctEvaluado,
        notaSimulada: inicial,
      );
    }).toList();
  }

  /// Aplica uno de los 3 presets automáticos sobre la lista de asignaturas.
  static List<ItemSimulacionCurso> aplicarPreset({
    required List<ItemSimulacionCurso> items,
    required PresetSimulacion preset,
  }) {
    // Rendimiento promedio de lo evaluado para el preset realista
    final itemsConNota = items.where((i) => i.notaActual != null).toList();
    final promedioActual = itemsConNota.isNotEmpty
        ? itemsConNota.fold<double>(0.0, (acc, i) => acc + i.notaActual!) /
            itemsConNota.length
        : 11.5;

    return items.map((item) {
      double nuevaNota;

      switch (preset) {
        case PresetSimulacion.minimoAprobatorio:
          nuevaNota = 10.5;
          break;

        case PresetSimulacion.realista:
          if (item.notaActual != null) {
            nuevaNota = item.notaActual!;
          } else {
            nuevaNota = promedioActual;
          }
          break;

        case PresetSimulacion.metaDistincion:
          if (item.notaActual != null && item.notaActual! > 16.0) {
            nuevaNota = item.notaActual!;
          } else {
            nuevaNota = 16.0;
          }
          break;
      }

      return item.copiarCon(
        notaSimulada: CalculosMultinivel.redondearUnDecimal(nuevaNota),
      );
    }).toList();
  }

  /// Calcula el promedio ponderado del ciclo simulado y proyecta el impacto en el PPA histórico.
  static ResultadoSimulacionCiclo calcularSimulacion({
    required List<ItemSimulacionCurso> items,
    double? ppaHistorico,
    int creditosHistoricos = 0,
    double umbralTercioSuperior = umbralTercioSuperiorDefault,
  }) {
    if (items.isEmpty) {
      return const ResultadoSimulacionCiclo(
        promedioSimulado: 0.0,
        totalCreditos: 0,
        creditosAprobados: 0,
        creditosDesaprobados: 0,
        esTercioSuperior: false,
        distanciaTercioSuperior: umbralTercioSuperiorDefault,
      );
    }

    double puntosPonderadosCiclo = 0.0;
    int sumaCreditos = 0;
    int aprobados = 0;
    int desaprobados = 0;

    for (final item in items) {
      final creds = item.creditosEfectivos;
      puntosPonderadosCiclo += item.notaSimulada * creds;
      sumaCreditos += creds;

      if (item.esAprobado) {
        aprobados += creds;
      } else {
        desaprobados += creds;
      }
    }

    final promedioCiclo = sumaCreditos > 0
        ? CalculosMultinivel.redondearUnDecimal(
            puntosPonderadosCiclo / sumaCreditos)
        : 0.0;

    // Proyección PPA (Promedio Ponderado Acumulado) Histórico
    double? ppaProyectado;
    double? impacto;

    if (ppaHistorico != null && creditosHistoricos > 0 && sumaCreditos > 0) {
      final puntosHistoricos = ppaHistorico * creditosHistoricos;
      final totalPuntos = puntosHistoricos + puntosPonderadosCiclo;
      final totalCredsAcumulados = creditosHistoricos + sumaCreditos;

      ppaProyectado = CalculosMultinivel.redondearUnDecimal(
          totalPuntos / totalCredsAcumulados);
      impacto = CalculosMultinivel.redondearUnDecimal(
          ppaProyectado - ppaHistorico);
    } else if (sumaCreditos > 0) {
      ppaProyectado = promedioCiclo;
    }

    final referenciaParaTercio = ppaProyectado ?? promedioCiclo;
    final esTercio = referenciaParaTercio >= umbralTercioSuperior;
    final distancia = esTercio
        ? 0.0
        : CalculosMultinivel.redondearUnDecimal(
            umbralTercioSuperior - referenciaParaTercio);

    return ResultadoSimulacionCiclo(
      promedioSimulado: promedioCiclo,
      totalCreditos: sumaCreditos,
      creditosAprobados: aprobados,
      creditosDesaprobados: desaprobados,
      ppaHistorico: ppaHistorico,
      creditosHistoricos: creditosHistoricos,
      ppaProyectado: ppaProyectado,
      impactoPpa: impacto,
      esTercioSuperior: esTercio,
      distanciaTercioSuperior: distancia,
    );
  }
}
