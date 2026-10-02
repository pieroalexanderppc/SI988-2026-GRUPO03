import 'package:cloud_firestore/cloud_firestore.dart';

class Ciclo {
  final String id;
  final String nombre;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  Ciclo({
    required this.id,
    required this.nombre,
    this.fechaInicio,
    this.fechaFin,
  });

  /// No incluimos el id en el Map porque es la llave del documento en Firestore.
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'fechaInicio': fechaInicio != null ? Timestamp.fromDate(fechaInicio!) : null,
      'fechaFin': fechaFin != null ? Timestamp.fromDate(fechaFin!) : null,
    };
  }

  factory Ciclo.fromMap(String documentId, Map<String, dynamic> map) {
    return Ciclo(
      id: documentId,
      nombre: map['nombre'] ?? '',
      fechaInicio: (map['fechaInicio'] as Timestamp?)?.toDate(),
      fechaFin: (map['fechaFin'] as Timestamp?)?.toDate(),
    );
  }
}
