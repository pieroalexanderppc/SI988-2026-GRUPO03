
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/curso.dart';
import '../models/unidad.dart';
import '../services/unidades_service.dart';
import 'tipos_evaluacion_screen.dart';

class UnidadesScreen extends StatefulWidget {
  final Curso curso;

  const UnidadesScreen({
    super.key,
    required this.curso,
  });

  @override
  State<UnidadesScreen> createState() => _UnidadesScreenState();
}

class _UnidadesScreenState extends State<UnidadesScreen> {
  final UnidadesService _service = UnidadesService();

  bool _ocupado = false;

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  Future<void> _mostrarFormulario({Unidad? unidad}) async {
    final nombreController = TextEditingController(
      text: unidad?.nombre ?? '',
    );

    final porcentajeController = TextEditingController(
      text: unidad == null ? '' : unidad.porcentaje.toString(),
    );

    final formKey = GlobalKey<FormState>();

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          unidad == null ? 'Nueva unidad' : 'Editar unidad',
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la unidad',
                    hintText: 'Ej. Unidad 1',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el nombre de la unidad.';
                    }
                    if (value.trim().length < 2) {
                      return 'Ingresa al menos 2 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: porcentajeController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Porcentaje (%)',
                    hintText: 'Ej. 25',
                    suffixText: '%',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final porcentaje = double.tryParse(
                      (value ?? '').trim().replaceAll(',', '.'),
                    );

                    if (porcentaje == null ||
                        !porcentaje.isFinite ||
                        porcentaje <= 0 ||
                        porcentaje > 100) {
                      return 'Ingresa un porcentaje entre 0 y 100.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, {
                  'nombre': nombreController.text.trim(),
                  'porcentaje': double.parse(
                    porcentajeController.text
                        .trim()
                        .replaceAll(',', '.'),
                  ),
                });
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    nombreController.dispose();
    porcentajeController.dispose();

    if (resultado == null || !mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _mostrarMensaje('Debes iniciar sesión.');
      return;
    }

    setState(() => _ocupado = true);

    try {
      final nombre = resultado['nombre'] as String;
      final porcentaje = resultado['porcentaje'] as double;

      if (unidad == null) {
        await _service.crearUnidad(
          user.uid,
          widget.curso.id,
          nombre,
          porcentaje,
        );

        _mostrarMensaje('Unidad creada correctamente.');
      } else {
        await _service.actualizarUnidad(
          user.uid,
          widget.curso.id,
          unidad,
          nombre,
          porcentaje,
        );

        _mostrarMensaje('Unidad actualizada correctamente.');
      }
    } catch (e) {
      _mostrarMensaje('No se pudo guardar la unidad: $e');
    } finally {
      if (mounted) {
        setState(() => _ocupado = false);
      }
    }
  }

  Future<void> _confirmarEliminar(Unidad unidad) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar unidad'),
        content: Text(
          '¿Deseas eliminar la unidad "${unidad.nombre}"?',
        ),
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

    if (confirmar != true || !mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _mostrarMensaje('Debes iniciar sesión.');
      return;
    }

    setState(() => _ocupado = true);

    try {
      await _service.eliminarUnidad(
        user.uid,
        widget.curso.id,
        unidad.id,
      );

      _mostrarMensaje('Unidad eliminada correctamente.');
    } catch (e) {
      _mostrarMensaje('No se pudo eliminar la unidad: $e');
    } finally {
      if (mounted) {
        setState(() => _ocupado = false);
      }
    }
  }

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

    return Scaffold(
      appBar: AppBar(
        title: Text('Unidades - ${widget.curso.nombre}'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ocupado ? null : () => _mostrarFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva unidad'),
      ),
      body: Stack(
        children: [
          StreamBuilder<List<Unidad>>(
            stream: _service.obtenerUnidades(
              user.uid,
              widget.curso.id,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error al cargar las unidades:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (snapshot.connectionState ==
                      ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final unidades = snapshot.data ?? <Unidad>[];

              final totalPorcentaje = unidades.fold<double>(
                0,
                (total, unidad) => total + unidad.porcentaje,
              );

              final porcentajeValido =
                  (totalPorcentaje - 100).abs() <= 0.1;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Distribución del curso',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                porcentajeValido
                                    ? Icons.check_circle
                                    : Icons.info_outline,
                                color: porcentajeValido
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Total: '
                                  '${totalPorcentaje.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                porcentajeValido
                                    ? 'Completo'
                                    : totalPorcentaje > 100
                                        ? 'Excede 100%'
                                        : 'Pendiente',
                                style: TextStyle(
                                  color: porcentajeValido
                                      ? Colors.green
                                      : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: (totalPorcentaje / 100)
                                .clamp(0.0, 1.0),
                            color: porcentajeValido
                                ? Colors.green
                                : null,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Los porcentajes de todas las unidades '
                            'deben sumar 100%.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (unidades.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 48,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Todavía no hay unidades.\n'
                            'Pulsa "Nueva unidad" para comenzar.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...unidades.map(
                      (unidad) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.menu_book),
                          ),
                          title: Text(
                            unidad.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Porcentaje: '
                            '${unidad.porcentaje.toStringAsFixed(1)}%',
                          ),
                          onTap: () {
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    TiposEvaluacionScreen(
                                  cursoId: widget.curso.id,
                                  unidad: unidad,
                                ),
                              ),
                            );
                          },
                          trailing: PopupMenuButton<String>(
                            enabled: !_ocupado,
                            onSelected: (opcion) {
                              if (opcion == 'editar') {
                                _mostrarFormulario(unidad: unidad);
                              } else if (opcion == 'eliminar') {
                                _confirmarEliminar(unidad);
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
                      ),
                    ),
                ],
              );
            },
          ),
          if (_ocupado)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
