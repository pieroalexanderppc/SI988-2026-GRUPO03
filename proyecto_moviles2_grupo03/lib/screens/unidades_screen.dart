import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/unidad.dart';
import '../services/unidades_service.dart';

class UnidadesScreen extends StatelessWidget {
  final String cursoId;
  final String cursoNombre;

  const UnidadesScreen({
    super.key,
    required this.cursoId,
    required this.cursoNombre,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Debes iniciar sesión.')),
      );
    }

    final service = UnidadesService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Unidades - $cursoNombre'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Unidad>>(
        stream: service.obtenerUnidades(user.uid, cursoId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al cargar las unidades.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final unidades = snapshot.data ?? [];

          final total = unidades.fold<double>(
            0,
            (suma, unidad) => suma + unidad.porcentaje,
          );

          final valido = unidades.isNotEmpty &&
              (total - 100).abs() <= 0.1;

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: ListTile(
                  leading: Icon(
                    valido ? Icons.check_circle : Icons.warning,
                    color: valido ? Colors.green : Colors.red,
                  ),
                  title: Text(
                    'Total: ${total.toStringAsFixed(1)}%',
                  ),
                  subtitle: Text(
                    valido
                        ? 'Porcentajes correctos'
                        : 'Los porcentajes deben sumar 100%',
                  ),
                ),
              ),
              Expanded(
                child: unidades.isEmpty
                    ? const Center(
                        child: Text('Todavía no hay unidades.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: unidades.length,
                        itemBuilder: (context, index) {
                          final unidad = unidades[index];

                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text('${index + 1}'),
                              ),
                              title: Text(unidad.nombre),
                              subtitle: Text(
                                '${unidad.porcentaje.toStringAsFixed(1)}%',
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (opcion) {
                                  if (opcion == 'editar') {
                                    _mostrarFormulario(
                                      context,
                                      service,
                                      user.uid,
                                      cursoId,
                                      unidad: unidad,
                                    );
                                  } else if (opcion == 'eliminar') {
                                    _eliminarUnidad(
                                      context,
                                      service,
                                      user.uid,
                                      cursoId,
                                      unidad,
                                    );
                                  }
                                },
                                itemBuilder: (_) => const [
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
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(
          context,
          service,
          user.uid,
          cursoId,
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nueva unidad'),
      ),
    );
  }

  static Future<void> _mostrarFormulario(
    BuildContext context,
    UnidadesService service,
    String uid,
    String cursoId, {
    Unidad? unidad,
  }) async {
    final nombreController = TextEditingController(
      text: unidad?.nombre ?? '',
    );
    final porcentajeController = TextEditingController(
      text: unidad?.porcentaje.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            unidad == null ? 'Nueva unidad' : 'Editar unidad',
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la unidad',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Escribe un nombre'
                          : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: porcentajeController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Porcentaje',
                    suffixText: '%',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final numero = double.tryParse(
                      (value ?? '').trim().replaceAll(',', '.'),
                    );

                    if (numero == null ||
                        !numero.isFinite ||
                        numero <= 0 ||
                        numero > 100) {
                      return 'Ingresa un valor mayor que 0 y hasta 100';
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final nombre = nombreController.text.trim();
                final porcentaje = double.parse(
                  porcentajeController.text.trim().replaceAll(',', '.'),
                );

                try {
                  if (unidad == null) {
                    await service.crearUnidad(
                      uid,
                      cursoId,
                      nombre,
                      porcentaje,
                    );
                  } else {
                    await service.actualizarUnidad(
                      uid,
                      cursoId,
                      unidad,
                      nombre,
                      porcentaje,
                    );
                  }

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          unidad == null
                              ? 'Unidad creada correctamente.'
                              : 'Unidad actualizada correctamente.',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se pudo guardar la unidad.'),
                      ),
                    );
                  }
                }
              },
              child: Text(unidad == null ? 'Crear' : 'Guardar'),
            ),
          ],
        ),
      );
    } finally {
      nombreController.dispose();
      porcentajeController.dispose();
    }
  }

  static Future<void> _eliminarUnidad(
    BuildContext context,
    UnidadesService service,
    String uid,
    String cursoId,
    Unidad unidad,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar unidad'),
        content: Text('¿Eliminar "${unidad.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await service.eliminarUnidad(uid, cursoId, unidad.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unidad eliminada correctamente.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo eliminar la unidad.'),
          ),
        );
      }
    }
  }
}