class Curso {
  final String id;
  final String nombre;
  final String? color; // Opcional para la UI

  Curso({required this.id, required this.nombre, this.color});

  factory Curso.fromMap(Map<String, dynamic> data, String documentId) {
    return Curso(
      id: documentId,
      nombre: data['nombre'] ?? '',
      color: data['color'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'nombre': nombre, if (color != null) 'color': color};
  }
}
