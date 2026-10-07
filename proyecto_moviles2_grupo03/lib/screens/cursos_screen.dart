import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/curso.dart';
import '../services/cursos_service.dart';

class CursosScreen extends StatelessWidget {
  final String cicloId;
  final String cicloNombre;

  const CursosScreen({
    super.key,
    required this.cicloId,
    required this.cicloNombre,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Debes iniciar sesión.'),
        ),
      );
    }

    final service = CursosService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Cursos - $cicloNombre'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Curso>>(
        stream: service.obtenerCursos(user.uid, cicloId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('No se pudieron cargar los cursos.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final cursos = snapshot.data ?? [];

          if (cursos.isEmpty) {
            return _EstadoVacio(
              onCrear: () => _mostrarDialogoCurso(
                context,
                service,
                user.uid,
                cicloId,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cursos.length,
            itemBuilder: (context, index) {
              final curso = cursos[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.book),
                  ),
                  title: Text(
                    curso.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (opcion) {
                      if (opcion == 'editar') {
                        _mostrarDialogoCurso(
                          context,
                          service,
                          user.uid,
                          cicloId,
                          curso: curso,
                        );
                      }

                      if (opcion == 'eliminar') {
                        _confirmarEliminar(
                          context,
                          service,
                          user.uid,
                          curso,
                        );
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'editar',
                        child: Text('Editar'),
                      ),
                      PopupMenuItem(
                        value: 'eliminar',
                        child: Text('Eliminar'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoCurso(
          context,
          service,
          user.uid,
          cicloId,
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo curso'),
      ),
    );
  }

  static Future<void> _mostrarDialogoCurso(
    BuildContext context,
    CursosService service,
    String uid,
    String cicloId, {
    Curso? curso,
  }) async {
    final controlador = TextEditingController(
      text: curso?.nombre ?? '',
    );

    final editar = curso != null;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            editar ? 'Editar curso' : 'Crear curso',
          ),
          content: TextField(
            controller: controlador,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre del curso',
              hintText: 'Ejemplo: Programación',
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
                      content: Text(
                        'Ingresa el nombre del curso.',
                      ),
                    ),
                  );
                  return;
                }

                try {
                  if (editar) {
                    await service.actualizarCurso(
                      uid,
                      curso,
                      nombre,
                    );
                  } else {
                    await service.crearCurso(
                      uid,
                      cicloId,
                      nombre,
                    );
                  }

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          editar
                              ? 'Curso actualizado correctamente.'
                              : 'Curso creado correctamente.',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No se pudo guardar el curso.',
                        ),
                      ),
                    );
                  }
                }
              },
              child: Text(
                editar ? 'Guardar' : 'Crear',
              ),
            ),
          ],
        );
      },
    );

    controlador.dispose();
  }

  static Future<void> _confirmarEliminar(
    BuildContext context,
    CursosService service,
    String uid,
    Curso curso,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar curso'),
          content: Text(
            '¿Deseas eliminar el curso "${curso.nombre}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(
                dialogContext,
                true,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await service.eliminarCurso(
        uid,
        curso.id,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Curso eliminado correctamente.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo eliminar el curso.',
            ),
          ),
        );
      }
    }
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
              Icons.book_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'No tienes cursos creados',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Agrega los cursos correspondientes a este ciclo.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCrear,
              icon: const Icon(Icons.add),
              label: const Text(
                'Crear mi primer curso',
              ),
            ),
          ],
        ),
      ),
    );
  }
}