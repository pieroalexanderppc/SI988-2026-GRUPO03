class TipoEvaluacion {
  final String id;
  final String nombre; // ej. 'Práctica', 'Examen', 'Laboratorio'
  final double peso; // Porcentaje que vale dentro de la unidad

  TipoEvaluacion({required this.id, required this.nombre, required this.peso});

  factory TipoEvaluacion.fromMap(Map<String, dynamic> data, String documentId) {
    return TipoEvaluacion(
      id: documentId,
      nombre: data['nombre'] ?? '',
      peso: (data['peso'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'nombre': nombre, 'peso': peso};
  }
}
