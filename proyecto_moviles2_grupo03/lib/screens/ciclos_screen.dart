import 'package:flutter/material.dart';
import '../models/ciclo.dart';
import '../services/ciclos_service.dart';

class CiclosScreen extends StatefulWidget {
  const CiclosScreen({super.key});

  @override
  State<CiclosScreen> createState() => _CiclosScreenState();
}

class _CiclosScreenState extends State<CiclosScreen> {
  final CiclosService _ciclosService = CiclosService();

  void _mostrarDialogoNuevoCiclo() {
    final TextEditingController nombreController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nuevo Ciclo'),
          content: TextField(
            controller: nombreController,
            decoration: const InputDecoration(
              hintText: 'Ej. 2026-I',
              labelText: 'Nombre del ciclo',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final nombre = nombreController.text.trim();
                if (nombre.isNotEmpty) {
                  _ciclosService.crearCiclo(nombre);
                  Navigator.pop(context);
                }
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  void _confirmarEliminarCiclo(Ciclo ciclo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar Ciclo'),
          content: Text(
            '¿Estás seguro que deseas eliminar el ciclo "${ciclo.nombre}"? '
            'Esta acción no se puede deshacer y eliminará sus cursos asociados.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                _ciclosService.eliminarCiclo(ciclo.id);
                Navigator.pop(context);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Ciclos'), centerTitle: true),
      body: StreamBuilder<List<Ciclo>>(
        stream: _ciclosService.getCiclos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ocurrió un error: ${snapshot.error}'));
          }

          final ciclos = snapshot.data ?? [];

          if (ciclos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tienes ningún ciclo creado',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Crea tu primer ciclo para empezar a organizar tus cursos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _mostrarDialogoNuevoCiclo,
                      icon: const Icon(Icons.add),
                      label: const Text('Crear mi primer ciclo'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: ciclos.length,
            itemBuilder: (context, index) {
              final ciclo = ciclos[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.folder_open)),
                  title: Text(
                    ciclo.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmarEliminarCiclo(ciclo),
                  ),
                  onTap: () {
                    // TODO: Navegar a la lista de cursos del ciclo
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Navegar a cursos de ${ciclo.nombre}'),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoNuevoCiclo,
        child: const Icon(Icons.add),
      ),
    );
  }
}
