class Curso {
  final String id;
  final String nombre;
  final String cicloId;

  Curso({
    required this.id,
    required this.nombre,
    required this.cicloId,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'cicloId': cicloId,
    };
  }

  factory Curso.fromMap(String documentId, Map<String, dynamic> map) {
    return Curso(
      id: documentId,
      nombre: map['nombre'] ?? '',
      cicloId: map['cicloId'] ?? '',
    );
  }
}
