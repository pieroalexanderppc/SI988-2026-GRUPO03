import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de datos para un recordatorio de evaluación (H26).
///
/// Permite al estudiante programar y visualizar fechas de exámenes,
/// entregas o prácticas de sus cursos.
class RecordatorioEvaluacion {
  final String id;
  final String titulo;
  final String cursoId;
  final String cursoNombre;
  final String? unidadId;
  final String? unidadNombre;
  final DateTime fecha;
  final String descripcion;
  final bool completado;
  final DateTime creadoEn;

  RecordatorioEvaluacion({
    required this.id,
    required this.titulo,
    required this.cursoId,
    required this.cursoNombre,
    this.unidadId,
    this.unidadNombre,
    required this.fecha,
    this.descripcion = '',
    this.completado = false,
    DateTime? creadoEn,
  }) : creadoEn = creadoEn ?? DateTime.now();

  /// Comprueba si la fecha del recordatorio ya pasó en comparación con el momento actual.
  bool get estaVencido {
    if (completado) return false;
    return fecha.isBefore(DateTime.now());
  }

  /// Comprueba si la evaluación está programada para el día de hoy.
  bool get esHoy {
    final now = DateTime.now();
    return fecha.year == now.year &&
        fecha.month == now.month &&
        fecha.day == now.day;
  }

  /// Comprueba si la evaluación es mañana.
  bool get esManana {
    final manana = DateTime.now().add(const Duration(days: 1));
    return fecha.year == manana.year &&
        fecha.month == manana.month &&
        fecha.day == manana.day;
  }

  /// Calcula los días completos faltantes hasta la fecha de la evaluación.
  int get diasRestantes {
    final now = DateTime.now();
    final inicioHoy = DateTime(now.year, now.month, now.day);
    final inicioFecha = DateTime(fecha.year, fecha.month, fecha.day);
    return inicioFecha.difference(inicioHoy).inDays;
  }

  /// Texto amigable para el chip de estado y tiempo restante.
  String get tiempoRestanteTexto {
    if (completado) return 'Rendida';
    if (estaVencido) {
      final dias = diasRestantes.abs();
      if (dias == 0) return 'Venció hoy';
      if (dias == 1) return 'Venció ayer';
      return 'Venció hace $dias días';
    }
    if (esHoy) {
      return 'Hoy';
    }
    if (esManana) {
      return 'Mañana';
    }
    final dias = diasRestantes;
    if (dias > 1) {
      return 'En $dias días';
    }
    return 'Próxima';
  }

  /// Formato corto de fecha y hora (ej. "12 Nov, 16:30").
  String get fechaFormateada {
    const meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Oct',
      'Nov',
      'Dic'
    ];
    final mes = meses[fecha.month - 1];
    final dia = fecha.day.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia $mes, $hora:$minuto';
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'cursoId': cursoId,
      'cursoNombre': cursoNombre,
      'unidadId': unidadId,
      'unidadNombre': unidadNombre,
      'fecha': Timestamp.fromDate(fecha),
      'descripcion': descripcion,
      'completado': completado,
      'creadoEn': Timestamp.fromDate(creadoEn),
    };
  }

  factory RecordatorioEvaluacion.fromMap(
      String documentId, Map<String, dynamic> map) {
    DateTime parseFecha(dynamic valor) {
      if (valor is Timestamp) return valor.toDate();
      if (valor is String) return DateTime.tryParse(valor) ?? DateTime.now();
      if (valor is int) return DateTime.fromMillisecondsSinceEpoch(valor);
      return DateTime.now();
    }

    return RecordatorioEvaluacion(
      id: documentId,
      titulo: map['titulo'] as String? ?? 'Evaluación',
      cursoId: map['cursoId'] as String? ?? '',
      cursoNombre: map['cursoNombre'] as String? ?? 'General',
      unidadId: map['unidadId'] as String?,
      unidadNombre: map['unidadNombre'] as String?,
      fecha: parseFecha(map['fecha']),
      descripcion: map['descripcion'] as String? ?? '',
      completado: map['completado'] as bool? ?? false,
      creadoEn: parseFecha(map['creadoEn']),
    );
  }

  RecordatorioEvaluacion copyWith({
    String? id,
    String? titulo,
    String? cursoId,
    String? cursoNombre,
    String? unidadId,
    String? unidadNombre,
    DateTime? fecha,
    String? descripcion,
    bool? completado,
    DateTime? creadoEn,
  }) {
    return RecordatorioEvaluacion(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      cursoId: cursoId ?? this.cursoId,
      cursoNombre: cursoNombre ?? this.cursoNombre,
      unidadId: unidadId ?? this.unidadId,
      unidadNombre: unidadNombre ?? this.unidadNombre,
      fecha: fecha ?? this.fecha,
      descripcion: descripcion ?? this.descripcion,
      completado: completado ?? this.completado,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }
}
