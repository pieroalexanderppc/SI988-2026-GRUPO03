
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistorialNotasScreen extends StatefulWidget {
  const HistorialNotasScreen({super.key});

  @override
  State<HistorialNotasScreen> createState() =>
      _HistorialNotasScreenState();
}

class _HistorialNotasScreenState extends State<HistorialNotasScreen> {
  late Future<List<Map<String, dynamic>>> _historial;

  @override
  void initState() {
    super.initState();
    _historial = _cargarHistorial();
  }

  Future<List<Map<String, dynamic>>> _cargarHistorial() async {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) return [];

    final db = FirebaseFirestore.instance;
    final resultado = <Map<String, dynamic>>[];

    final cursos = await db
        .collection('usuarios')
        .doc(usuario.uid)
        .collection('cursos')
        .get();

    for (final curso in cursos.docs) {
      final unidades = await curso.reference
          .collection('unidades')
          .get();

      for (final unidad in unidades.docs) {
        final tipos = await unidad.reference
            .collection('tiposEvaluacion')
            .get();

        for (final tipo in tipos.docs) {
          final notas = await tipo.reference
              .collection('notas')
              .get();

          for (final nota in notas.docs) {
            final data = nota.data();

            resultado.add({
              'curso': curso.data()['nombre'] ?? 'Curso',
              'unidad': unidad.data()['nombre'] ?? 'Unidad',
              'tipo': tipo.data()['nombre'] ?? 'Evaluación',
              'nombre': data['nombre'] ?? '',
              'valor': (data['valor'] as num?)?.toDouble() ?? 0.0,
              'fecha': (data['fecha'] as Timestamp?)?.toDate(),
            });
          }
        }
      }
    }

    resultado.sort((a, b) {
      final fechaA = a['fecha'] as DateTime?;
      final fechaB = b['fecha'] as DateTime?;

      if (fechaA == null) return 1;
      if (fechaB == null) return -1;
      return fechaB.compareTo(fechaA);
    });

    return resultado;
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Sin fecha';

    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de notas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _historial = _cargarHistorial();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historial,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar notas: ${snapshot.error}'),
            );
          }

          final notas = snapshot.data ?? [];

          if (notas.isEmpty) {
            return const Center(
              child: Text('No hay notas registradas.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notas.length,
            itemBuilder: (context, index) {
              final nota = notas[index];
              final valor = nota['valor'] as double;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade100,
                    child: Text(
                      valor.toStringAsFixed(0),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                  title: Text(
                    nota['nombre'].toString().isNotEmpty
                        ? nota['nombre']
                        : nota['tipo'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${nota['curso']} • ${nota['unidad']}\n'
                    '${nota['tipo']} • '
                    '${_formatearFecha(nota['fecha'])}',
                  ),
                  trailing: Text(
                    '${valor.toStringAsFixed(1)}/20',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: valor >= 11
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}