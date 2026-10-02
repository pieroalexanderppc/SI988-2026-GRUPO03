class Ciclo {
  final String id;
  final String nombre; // ej. '2026-I'

  Ciclo({required this.id, required this.nombre});

  factory Ciclo.fromMap(Map<String, dynamic> data, String documentId) {
    return Ciclo(id: documentId, nombre: data['nombre'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'nombre': nombre};
  }
}
