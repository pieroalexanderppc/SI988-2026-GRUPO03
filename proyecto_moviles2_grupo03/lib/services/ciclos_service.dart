import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ciclo.dart';

class CiclosService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference get _ciclosRef {
    final uid = _uid ?? 'test_user_uid'; // Fallback temporal para pruebas
    return _db.collection('usuarios').doc(uid).collection('ciclos');
  }

  /// Obtiene un stream de ciclos ordenados (por nombre o creación)
  Stream<List<Ciclo>> getCiclos() {
    return _ciclosRef
        .orderBy(
          'nombre',
          descending: true,
        ) // Se puede ordenar por fecha si se agrega
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Ciclo.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();
        });
  }

  /// Crea un nuevo ciclo
  Future<void> crearCiclo(String nombre) async {
    await _ciclosRef.add({
      'nombre': nombre,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Elimina un ciclo (Nota: Para eliminar subcolecciones se requiere Cloud Functions
  /// o eliminación recursiva manual. Aquí eliminamos el documento base por simplicidad).
  Future<void> eliminarCiclo(String cicloId) async {
    await _ciclosRef.doc(cicloId).delete();
  }
}
