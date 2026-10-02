import 'package:cloud_firestore/cloud_firestore.dart';

class Nota {
  final String id;
  final double valor;
  final DateTime? fecha;
  final String tipoEvaluacionId;

  Nota({
    required this.id,
    required this.valor,
    this.fecha,
    required this.tipoEvaluacionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'valor': valor,
      'fecha': fecha != null ? Timestamp.fromDate(fecha!) : null,
      'tipoEvaluacionId': tipoEvaluacionId,
    };
  }

  factory Nota.fromMap(String documentId, Map<String, dynamic> map) {
    return Nota(
      id: documentId,
      valor: (map['valor'] ?? 0.0).toDouble(),
      fecha: (map['fecha'] as Timestamp?)?.toDate(),
      tipoEvaluacionId: map['tipoEvaluacionId'] ?? '',
    );
  }
}
