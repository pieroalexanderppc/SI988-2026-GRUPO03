import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/ciclo.dart';
import '../services/ciclos_service.dart';

class CiclosScreen extends StatelessWidget {
  const CiclosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Debes iniciar sesión para gestionar tus ciclos.'),
        ),
      );
    }

    final ciclosService = CiclosService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis ciclos'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Ciclo>>(
        stream: ciclosService.obtenerCiclos(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No se pudieron cargar los ciclos.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final ciclos = snapshot.data ?? [];

          if (ciclos.isEmpty) {
            return _EstadoVacio(
              onCrear: () => _mostrarDialogoCrear(context, ciclosService, user.uid),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ciclos.length,
            itemBuilder: (context, index) {
              final ciclo = ciclos[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.calendar_month),
                  ),
                  title: Text(
                    ciclo.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: ciclo.fechaInicio != null
                      ? Text(
                          'Creado: ${_formatearFecha(ciclo.fechaInicio!)}',
                        )
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Eliminar ciclo',
                    onPressed: () => _confirmarEliminar(
                      context,
                      ciclosService,
                      user.uid,
                      ciclo,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _mostrarDialogoCrear(context, ciclosService, user.uid),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo ciclo'),
      ),
    );
  }

  static Future<void> _mostrarDialogoCrear(
    BuildContext context,
    CiclosService service,
    String uid,
  ) async {
    final controlador = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Crear ciclo'),
          content: TextField(
            controller: controlador,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre del ciclo',
              hintText: 'Ejemplo: 2026-I',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final nombre = controlador.text.trim();

                if (nombre.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingresa el nombre del ciclo.'),
                    ),
                  );
                  return;
                }

                try {
                  await service.crearCiclo(uid, nombre);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ciclo creado correctamente.'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se pudo crear el ciclo.'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );

    controlador.dispose();
  }

  static Future<void> _confirmarEliminar(
    BuildContext context,
    CiclosService service,
    String uid,
    Ciclo ciclo,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar ciclo'),
          content: Text(
            '¿Deseas eliminar el ciclo "${ciclo.nombre}"?\n\n'
            'También se eliminarán los cursos asociados a este ciclo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await service.eliminarCiclo(uid, ciclo.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ciclo eliminado correctamente.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo eliminar el ciclo.'),
          ),
        );
      }
    }
  }

  static String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }
}

class _EstadoVacio extends StatelessWidget {
  final VoidCallback onCrear;

  const _EstadoVacio({
    required this.onCrear,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'No tienes ciclos creados',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Crea tu primer ciclo académico para comenzar a organizar tus cursos.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCrear,
              icon: const Icon(Icons.add),
              label: const Text('Crear mi primer ciclo'),
            ),
          ],
        ),
      ),
    );
  }
}