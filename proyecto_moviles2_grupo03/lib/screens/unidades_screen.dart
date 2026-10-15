import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/unidad.dart';
import '../services/calculo_curso_service.dart';
import '../services/calculos_multinivel.dart';
import '../services/unidades_service.dart';
import 'tipos_evaluacion_screen.dart';

class UnidadesScreen extends StatefulWidget {
  final String cursoId;
  final String cursoNombre;

  const UnidadesScreen({
    super.key,
    required this.cursoId,
    required this.cursoNombre,
  });

  @override
  State<UnidadesScreen> createState() => _UnidadesScreenState();
}

class _UnidadesScreenState extends State<UnidadesScreen> {
  final UnidadesService _service = UnidadesService();
  final CalculoCursoService _calculoService = CalculoCursoService();

  ResultadoCalculoCurso? _resultadoCalculo;
  bool _cargandoCalculo = false;

  @override
  void initState() {
    super.initState();
    _actualizarCalculo();
  }

  Future<void> _actualizarCalculo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (mounted) {
      setState(() => _cargandoCalculo = true);
    }

    try {
      final resultado = await _calculoService.obtenerCalculoCurso(
        user.uid,
        widget.cursoId,
      );
      if (mounted) {
        setState(() {
          _resultadoCalculo = resultado;
          _cargandoCalculo = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _cargandoCalculo = false);
      }
    }
  }

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
        title: Text('Unidades - ${widget.cursoNombre}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _cargandoCalculo
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Recalcular promedio',
            onPressed: _cargandoCalculo ? null : _actualizarCalculo,
          ),
        ],
      ),
      body: StreamBuilder<List<Unidad>>(
        stream: _service.obtenerUnidades(user.uid, widget.cursoId),
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

          final valido = unidades.isNotEmpty && (total - 100).abs() <= 0.1;

          return RefreshIndicator(
            onRefresh: _actualizarCalculo,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Tarjeta destacada de la Nota Final del Curso (H14)
                _TarjetaNotaFinalCurso(
                  resultado: _resultadoCalculo,
                  cargando: _cargandoCalculo,
                ),
                const SizedBox(height: 12),

                // 2. Indicador de suma de 100% de unidades (H12)
                Card(
                  child: ListTile(
                    leading: Icon(
                      valido ? Icons.check_circle : Icons.warning,
                      color: valido ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      'Total unidades: ${total.toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      valido
                          ? 'Porcentajes correctos'
                          : 'Los porcentajes de las unidades deben sumar 100%',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Título de la sección de unidades
                Text(
                  'Unidades del curso (${unidades.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),

                // 3. Lista de unidades
                if (unidades.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Text('Todavía no hay unidades registradas.'),
                    ),
                  )
                else
                  for (int index = 0; index < unidades.length; index++) ...[
                    _buildUnidadItem(context, user.uid, unidades[index], index),
                    const SizedBox(height: 8),
                  ],
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await _mostrarFormulario(
            context,
            _service,
            user.uid,
            widget.cursoId,
          );
          _actualizarCalculo();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva unidad'),
      ),
    );
  }

  Widget _buildUnidadItem(
    BuildContext context,
    String uid,
    Unidad unidad,
    int index,
  ) {
    final notaUnidad = _resultadoCalculo?.notasPorUnidad[unidad.id];
    final estaCompleta = _resultadoCalculo?.unidadCompleta[unidad.id] ?? false;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text('${index + 1}'),
        ),
        title: Text(
          unidad.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text('Peso: ${unidad.porcentaje.toStringAsFixed(1)}%'),
            const SizedBox(height: 2),
            Text(
              notaUnidad != null
                  ? 'Nota: ${notaUnidad.toStringAsFixed(1)} / 20 ${estaCompleta ? "(completa)" : "(parcial)"}'
                  : 'Nota: Sin notas registradas',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: notaUnidad == null
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : (notaUnidad >= 10.5 ? Colors.green.shade700 : Colors.red.shade700),
              ),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TiposEvaluacionScreen(
                cursoId: widget.cursoId,
                cursoNombre: widget.cursoNombre,
                unidadId: unidad.id,
                unidadNombre: unidad.nombre,
                unidadPorcentaje: unidad.porcentaje,
              ),
            ),
          );
          // Al volver de TiposEvaluacionScreen, actualizar el cálculo en tiempo real
          _actualizarCalculo();
        },
        trailing: PopupMenuButton<String>(
          onSelected: (opcion) async {
            if (opcion == 'editar') {
              await _mostrarFormulario(
                context,
                _service,
                uid,
                widget.cursoId,
                unidad: unidad,
              );
              _actualizarCalculo();
            } else if (opcion == 'eliminar') {
              await _eliminarUnidad(
                context,
                _service,
                uid,
                widget.cursoId,
                unidad,
              );
              _actualizarCalculo();
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
      text: unidad != null ? unidad.porcentaje.toString() : '',
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
                  keyboardType: const TextInputType.numberWithOptions(
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

/// Tarjeta destacada superior que muestra la Nota Final del Curso (H14)
class _TarjetaNotaFinalCurso extends StatelessWidget {
  final ResultadoCalculoCurso? resultado;
  final bool cargando;

  const _TarjetaNotaFinalCurso({
    required this.resultado,
    required this.cargando,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (cargando && resultado == null) {
      return Card(
        color: colorScheme.surfaceContainerHigh,
        child: const Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Calculando promedio del curso...'),
              ],
            ),
          ),
        ),
      );
    }

    if (resultado == null || resultado!.estado == EstadoCalculoCurso.sinDatos) {
      return Card(
        color: colorScheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Promedio final del curso',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      resultado?.mensajeEstado ??
                          'Registra notas en tus unidades para calcular el promedio final.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Caso 1: Cálculo Incompleto (Criterio 3 de H14)
    if (resultado!.estado == EstadoCalculoCurso.incompleto) {
      return Card(
        color: Colors.amber.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.amber.shade300, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.pending_actions, color: Colors.amber.shade900),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cálculo pendiente / incompleto',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.amber.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          resultado!.mensajeEstado,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.brown.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (resultado!.notaAcumulada != null) ...[
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nota acumulada parcial:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.brown.shade800,
                      ),
                    ),
                    Text(
                      '${resultado!.notaAcumulada!.toStringAsFixed(1)} / 20',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Caso 2: Cálculo Completo (Criterios 1 y 2 de H14)
    final nota = resultado!.notaFinal!;
    final aprobado = resultado!.esAprobado;

    return Card(
      color: colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nota final del curso',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${nota.toStringAsFixed(1)} / 20',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: aprobado ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
            Chip(
              avatar: Icon(
                aprobado ? Icons.check_circle : Icons.cancel,
                size: 18,
                color: Colors.white,
              ),
              backgroundColor: aprobado ? Colors.green.shade600 : Colors.red.shade600,
              label: Text(
                aprobado ? 'Aprobado' : 'Desaprobado',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}