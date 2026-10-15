import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/nota.dart';
import '../models/tipo_evaluacion.dart';
import '../services/calculos_evaluaciones.dart';
import '../services/evaluaciones_service.dart';

class TiposEvaluacionScreen extends StatefulWidget {
  final String cursoId;
  final String cursoNombre;
  final String unidadId;
  final String unidadNombre;
  final double unidadPorcentaje;

  const TiposEvaluacionScreen({
    super.key,
    required this.cursoId,
    required this.cursoNombre,
    required this.unidadId,
    required this.unidadNombre,
    required this.unidadPorcentaje,
  });

  @override
  State<TiposEvaluacionScreen> createState() => _TiposEvaluacionScreenState();
}

class _TiposEvaluacionScreenState extends State<TiposEvaluacionScreen> {
  final EvaluacionesService _service = EvaluacionesService();
  final Map<String, List<Nota>> _notasPorTipo = {};

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Debes iniciar sesión.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.unidadNombre} - ${widget.cursoNombre}'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<TipoEvaluacion>>(
        stream: _service.obtenerTiposEvaluacion(
          user.uid,
          widget.cursoId,
          widget.unidadId,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al cargar los tipos de evaluación.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tipos = snapshot.data ?? [];
          final totalPorcentaje = CalculosEvaluaciones.calcularTotalPorcentaje(tipos);
          final porcentajeValido = CalculosEvaluaciones.validarSumaPorcentajes(tipos);
          final notaUnidad = CalculosEvaluaciones.calcularNotaUnidad(tipos, _notasPorTipo);

          return CustomScrollView(
            slivers: [
              // Indicadores superiores
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      // Indicador de suma de 100% (Igual a H12)
                      Card(
                        child: ListTile(
                          leading: Icon(
                            porcentajeValido ? Icons.check_circle : Icons.warning,
                            color: porcentajeValido ? Colors.green : Colors.red,
                          ),
                          title: Text(
                            'Total pesos: ${totalPorcentaje.toStringAsFixed(1)}%',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            porcentajeValido
                                ? 'Porcentajes correctos'
                                : 'Los tipos de evaluación deben sumar 100%',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tarjeta de Nota de la Unidad
                      Card(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nota de la unidad (${widget.unidadPorcentaje.toStringAsFixed(0)}% del curso)',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notaUnidad != null
                                        ? notaUnidad.toStringAsFixed(2)
                                        : 'Sin notas',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: notaUnidad == null
                                          ? Theme.of(context).colorScheme.onSurfaceVariant
                                          : (CalculosEvaluaciones.esAprobado(notaUnidad)
                                              ? Colors.green.shade700
                                              : Colors.red.shade700),
                                    ),
                                  ),
                                ],
                              ),
                              if (notaUnidad != null)
                                Chip(
                                  avatar: Icon(
                                    CalculosEvaluaciones.esAprobado(notaUnidad)
                                        ? Icons.check
                                        : Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  backgroundColor: CalculosEvaluaciones.esAprobado(notaUnidad)
                                      ? Colors.green.shade600
                                      : Colors.red.shade600,
                                  label: Text(
                                    CalculosEvaluaciones.esAprobado(notaUnidad)
                                        ? 'Aprobado'
                                        : 'Desaprobado',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Lista de tipos de evaluación
              if (tipos.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Todavía no hay tipos de evaluación.\nPresiona el botón "+" para agregar uno (ej. Exámenes, Laboratorios).',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tipo = tipos[index];
                        return _TipoEvaluacionCard(
                          key: ValueKey(tipo.id),
                          tipo: tipo,
                          uid: user.uid,
                          cursoId: widget.cursoId,
                          unidadId: widget.unidadId,
                          service: _service,
                          onNotasActualizadas: (notas) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _notasPorTipo[tipo.id] = notas;
                                });
                              }
                            });
                          },
                          onEditarTipo: () => _mostrarFormularioTipo(
                            context,
                            user.uid,
                            tipo: tipo,
                          ),
                          onEliminarTipo: () => _confirmarEliminarTipo(
                            context,
                            user.uid,
                            tipo,
                          ),
                        );
                      },
                      childCount: tipos.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioTipo(context, user.uid),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo tipo'),
      ),
    );
  }

  Future<void> _mostrarFormularioTipo(
    BuildContext context,
    String uid, {
    TipoEvaluacion? tipo,
  }) async {
    final nombreController = TextEditingController(text: tipo?.nombre ?? '');
    final porcentajeController = TextEditingController(
      text: tipo != null ? tipo.porcentaje.toString() : '',
    );
    final formKey = GlobalKey<FormState>();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(tipo == null ? 'Nuevo tipo de evaluación' : 'Editar tipo de evaluación'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre (ej. Laboratorio, Examen)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Escribe un nombre' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: porcentajeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Peso / Porcentaje',
                    suffixText: '%',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final numero = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
                    if (numero == null || !numero.isFinite || numero <= 0 || numero > 100) {
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
                  if (tipo == null) {
                    await _service.crearTipoEvaluacion(
                      uid,
                      widget.cursoId,
                      widget.unidadId,
                      nombre,
                      porcentaje,
                    );
                  } else {
                    await _service.actualizarTipoEvaluacion(
                      uid,
                      widget.cursoId,
                      widget.unidadId,
                      tipo,
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
                          tipo == null
                              ? 'Tipo de evaluación creado.'
                              : 'Tipo de evaluación actualizado.',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se pudo guardar el tipo de evaluación.'),
                      ),
                    );
                  }
                }
              },
              child: Text(tipo == null ? 'Crear' : 'Guardar'),
            ),
          ],
        ),
      );
    } finally {
      nombreController.dispose();
      porcentajeController.dispose();
    }
  }

  Future<void> _confirmarEliminarTipo(
    BuildContext context,
    String uid,
    TipoEvaluacion tipo,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar tipo de evaluación'),
        content: Text(
          '¿Eliminar "${tipo.nombre}" y todas las notas registradas en él?',
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

    if (confirmar != true) return;

    try {
      await _service.eliminarTipoEvaluacion(
        uid,
        widget.cursoId,
        widget.unidadId,
        tipo.id,
      );

      setState(() {
        _notasPorTipo.remove(tipo.id);
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tipo de evaluación eliminado.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar el tipo de evaluación.')),
        );
      }
    }
  }
}

class _TipoEvaluacionCard extends StatelessWidget {
  final TipoEvaluacion tipo;
  final String uid;
  final String cursoId;
  final String unidadId;
  final EvaluacionesService service;
  final ValueChanged<List<Nota>> onNotasActualizadas;
  final VoidCallback onEditarTipo;
  final VoidCallback onEliminarTipo;

  const _TipoEvaluacionCard({
    super.key,
    required this.tipo,
    required this.uid,
    required this.cursoId,
    required this.unidadId,
    required this.service,
    required this.onNotasActualizadas,
    required this.onEditarTipo,
    required this.onEliminarTipo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: StreamBuilder<List<Nota>>(
        stream: service.obtenerNotas(uid, cursoId, unidadId, tipo.id),
        builder: (context, snapshot) {
          final notas = snapshot.data ?? [];
          onNotasActualizadas(notas);

          final promedioTipo = CalculosEvaluaciones.calcularPromedioTipo(notas);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera del Tipo
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tipo.nombre,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Peso en la unidad: ${tipo.porcentaje.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge del promedio del tipo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: promedioTipo == null
                            ? Theme.of(context).colorScheme.surfaceContainerHigh
                            : (CalculosEvaluaciones.esAprobado(promedioTipo)
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.red.withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        promedioTipo == null
                            ? 'Promedio: --'
                            : 'Promedio: ${promedioTipo.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: promedioTipo == null
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : (CalculosEvaluaciones.esAprobado(promedioTipo)
                                  ? Colors.green.shade800
                                  : Colors.red.shade800),
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (opcion) {
                        if (opcion == 'editar') {
                          onEditarTipo();
                        } else if (opcion == 'eliminar') {
                          onEliminarTipo();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'editar',
                          child: Text('Editar tipo'),
                        ),
                        PopupMenuItem(
                          value: 'eliminar',
                          child: Text('Eliminar tipo'),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Lista de notas y botón para agregar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notas registradas (${notas.length}):',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _mostrarDialogoNota(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Agregar nota'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                if (notas.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No hay notas registradas en este tipo de evaluación.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (int i = 0; i < notas.length; i++)
                        _NotaChip(
                          index: i + 1,
                          nota: notas[i],
                          onEditar: () => _mostrarDialogoNota(
                            context,
                            nota: notas[i],
                          ),
                          onEliminar: () => _confirmarEliminarNota(
                            context,
                            notas[i],
                            i + 1,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _mostrarDialogoNota(
    BuildContext context, {
    Nota? nota,
  }) async {
    final controller = TextEditingController(
      text: nota != null ? nota.valor.toString() : '',
    );
    final formKey = GlobalKey<FormState>();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(nota == null ? 'Registrar nota' : 'Editar nota'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nota (0 - 20)',
                    hintText: 'Ej. 16.5',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final numero = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
                    if (numero == null || !numero.isFinite || numero < 0 || numero > 20) {
                      return 'Ingresa una nota válida entre 0 y 20';
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

                final valor = double.parse(
                  controller.text.trim().replaceAll(',', '.'),
                );

                try {
                  if (nota == null) {
                    await service.crearNota(
                      uid,
                      cursoId,
                      unidadId,
                      tipo.id,
                      valor,
                    );
                  } else {
                    await service.actualizarNota(
                      uid,
                      cursoId,
                      unidadId,
                      tipo.id,
                      nota.id,
                      valor,
                    );
                  }

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          nota == null ? 'Nota agregada.' : 'Nota actualizada.',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se pudo guardar la nota.')),
                    );
                  }
                }
              },
              child: Text(nota == null ? 'Agregar' : 'Guardar'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _confirmarEliminarNota(
    BuildContext context,
    Nota nota,
    int index,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar nota'),
        content: Text(
          '¿Deseas eliminar la Nota #$index (${nota.valor})?',
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

    if (confirmar != true) return;

    try {
      await service.eliminarNota(uid, cursoId, unidadId, tipo.id, nota.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota eliminada.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar la nota.')),
        );
      }
    }
  }
}

class _NotaChip extends StatelessWidget {
  final int index;
  final Nota nota;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _NotaChip({
    required this.index,
    required this.nota,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final esAprobado = CalculosEvaluaciones.esAprobado(nota.valor);

    return InkWell(
      onTap: onEditar,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: esAprobado
              ? Colors.green.withValues(alpha: 0.12)
              : Colors.red.withValues(alpha: 0.12),
          border: Border.all(
            color: esAprobado
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.red.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#$index: ',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              nota.valor.toStringAsFixed(1),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: esAprobado ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: onEliminar,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(2.0),
                child: Icon(Icons.close, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
