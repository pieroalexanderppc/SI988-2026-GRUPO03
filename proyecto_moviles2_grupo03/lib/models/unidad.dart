class Unidad {
  final String id;
  final String nombre;
  final String cursoId;

  Unidad({
    required this.id,
    required this.nombre,
    required this.cursoId,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'cursoId': cursoId,
    };
  }

  factory Unidad.fromMap(String documentId, Map<String, dynamic> map) {
    return Unidad(
      id: documentId,
      nombre: map['nombre'] ?? '',
      cursoId: map['cursoId'] ?? '',
    );
  }
}
