class Nota {
  final String id;
  final String nombre; // ej. 'Práctica 1', 'Examen Parcial'
  final double valor; // Nota obtenida, ej. 18.5
  final double peso; // Peso específico de esta nota, ej. 100.0 si es la única
  final DateTime? fecha;

  Nota({
    required this.id,
    required this.nombre,
    required this.valor,
    required this.peso,
    this.fecha,
  });

  factory Nota.fromMap(Map<String, dynamic> data, String documentId) {
    return Nota(
      id: documentId,
      nombre: data['nombre'] ?? '',
      valor: (data['valor'] ?? 0.0).toDouble(),
      peso: (data['peso'] ?? 0.0).toDouble(),
      fecha: data['fecha'] != null
          ? DateTime.tryParse(data['fecha'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'valor': valor,
      'peso': peso,
      if (fecha != null) 'fecha': fecha!.toIso8601String(),
    };
  }
}
