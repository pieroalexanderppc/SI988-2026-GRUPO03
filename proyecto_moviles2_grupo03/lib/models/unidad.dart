class Unidad {
  final String id;
  final String nombre; // ej. 'Unidad 1'
  final double peso; // Porcentaje que vale de la nota final del curso

  Unidad({required this.id, required this.nombre, required this.peso});

  factory Unidad.fromMap(Map<String, dynamic> data, String documentId) {
    return Unidad(
      id: documentId,
      nombre: data['nombre'] ?? '',
      peso: (data['peso'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'nombre': nombre, 'peso': peso};
  }
}
