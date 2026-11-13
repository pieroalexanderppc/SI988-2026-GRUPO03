import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/curso.dart';
import '../models/recordatorio_evaluacion.dart';
import '../services/cursos_service.dart';
import '../services/notificaciones_service.dart';
import '../services/recordatorios_service.dart';
import '../widgets/app_bar_nivel.dart';
import '../widgets/dialogos.dart';
import '../widgets/estado_vacio.dart';

enum FiltroRecordatorios { pendientes, todos, rendidas }

/// Pantalla para la gestión (CRUD) de recordatorios de evaluaciones (H26).
class RecordatoriosScreen extends StatefulWidget {
  final String? cursoId;
  final String? cursoNombre;

  const RecordatoriosScreen({
    super.key,
    this.cursoId,
    this.cursoNombre,
  });

  @override
  State<RecordatoriosScreen> createState() => _RecordatoriosScreenState();
}

class _RecordatoriosScreenState extends State<RecordatoriosScreen> {
  final RecordatoriosService _service = RecordatoriosService();
  CursosService? _cursosService;

  String _uid = '';
  Stream<List<RecordatorioEvaluacion>>? _recordatoriosStream;
  List<Curso> _cursosDisponibles = [];
  FiltroRecordatorios _filtro = FiltroRecordatorios.pendientes;

  @override
  void initState() {
    super.initState();
    try {
      _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      _uid = '';
    }
    _cargarDatos();
    _solicitarPermisosNotificaciones();
  }

  void _solicitarPermisosNotificaciones() {
    try {
      NotificacionesService().solicitarPermisos();
    } catch (_) {}
  }

  void _cargarDatos() {
    if (widget.cursoId != null && widget.cursoId!.isNotEmpty) {
      _recordatoriosStream =
          _service.obtenerRecordatoriosPorCurso(_uid, widget.cursoId!);
    } else {
      _recordatoriosStream = _service.obtenerRecordatorios(_uid);
    }

    if (_uid.isNotEmpty) {
      // Cargamos cursos para el dropdown de creación
      _cursosService ??= CursosService();
      _cursosService!.obtenerCursos(_uid, '').listen(
        (cursos) {
          if (mounted) setState(() => _cursosDisponibles = cursos);
        },
        onError: (_) {},
      );
    }
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _crearOEditarRecordatorio({
    RecordatorioEvaluacion? existente,
  }) async {
    final esEdicion = existente != null;
    final formKey = GlobalKey<FormState>();

    final tituloCtrl =
        TextEditingController(text: existente?.titulo ?? '');
    final descCtrl =
        TextEditingController(text: existente?.descripcion ?? '');
    String cursoSeleccionadoId =
        existente?.cursoId ?? widget.cursoId ?? '';
    String cursoSeleccionadoNombre =
        existente?.cursoNombre ?? widget.cursoNombre ?? '';

    final cursoTextoCtrl = TextEditingController(
      text: cursoSeleccionadoNombre.isNotEmpty
          ? cursoSeleccionadoNombre
          : 'General',
    );

    DateTime fechaSeleccionada =
        existente?.fecha ?? DateTime.now().add(const Duration(days: 2));
    TimeOfDay horaSeleccionada = TimeOfDay(
      hour: fechaSeleccionada.hour,
      minute: fechaSeleccionada.minute,
    );

    bool notificar = existente?.notificar ?? true;
    int antelacionHoras = existente?.antelacionHoras ?? 24;

    final resultado = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final scheme = Theme.of(context).colorScheme;

          Future<void> seleccionarFecha() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: fechaSeleccionada,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
            );
            if (picked != null) {
              setDialogState(() {
                fechaSeleccionada = DateTime(
                  picked.year,
                  picked.month,
                  picked.day,
                  horaSeleccionada.hour,
                  horaSeleccionada.minute,
                );
              });
            }
          }

          Future<void> seleccionarHora() async {
            final picked = await showTimePicker(
              context: context,
              initialTime: horaSeleccionada,
            );
            if (picked != null) {
              setDialogState(() {
                horaSeleccionada = picked;
                fechaSeleccionada = DateTime(
                  fechaSeleccionada.year,
                  fechaSeleccionada.month,
                  fechaSeleccionada.day,
                  picked.hour,
                  picked.minute,
                );
              });
            }
          }

          return AlertDialog(
            title: Text(esEdicion
                ? 'Editar recordatorio'
                : 'Nuevo recordatorio'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Título
                    TextFormField(
                      controller: tituloCtrl,
                      autofocus: !esEdicion,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Título de la evaluación *',
                        hintText: 'Ej. Examen Parcial, Entrega Lab 4',
                        prefixIcon: Icon(Icons.edit_calendar_rounded),
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Ingresa un título para la evaluación'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Curso (Dropdown o Campo de texto)
                    if (_cursosDisponibles.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: cursoSeleccionadoId.isNotEmpty &&
                                _cursosDisponibles.any(
                                    (c) => c.id == cursoSeleccionadoId)
                            ? cursoSeleccionadoId
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Curso asociado *',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        items: _cursosDisponibles.map((c) {
                          return DropdownMenuItem<String>(
                            value: c.id,
                            child: Text(c.nombre,
                                overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final c = _cursosDisponibles
                                .firstWhere((e) => e.id == val);
                            setDialogState(() {
                              cursoSeleccionadoId = c.id;
                              cursoSeleccionadoNombre = c.nombre;
                              cursoTextoCtrl.text = c.nombre;
                            });
                          }
                        },
                        validator: (v) {
                          if (cursoSeleccionadoNombre.trim().isEmpty &&
                              (v == null || v.isEmpty)) {
                            return 'Selecciona un curso';
                          }
                          return null;
                        },
                      )
                    else
                      TextFormField(
                        controller: cursoTextoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del curso',
                          hintText: 'Ej. Soluciones Móviles II',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        onChanged: (val) {
                          cursoSeleccionadoNombre = val;
                        },
                      ),
                    const SizedBox(height: 16),

                    // Selector de Fecha y Hora
                    Text(
                      'Fecha y hora de la evaluación',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today_rounded,
                                size: 18),
                            label: Text(
                              '${fechaSeleccionada.day.toString().padLeft(2, '0')}/${fechaSeleccionada.month.toString().padLeft(2, '0')}/${fechaSeleccionada.year}',
                            ),
                            onPressed: seleccionarFecha,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time_rounded,
                                size: 18),
                            label: Text(
                              '${horaSeleccionada.hour.toString().padLeft(2, '0')}:${horaSeleccionada.minute.toString().padLeft(2, '0')}',
                            ),
                            onPressed: seleccionarHora,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Descripción / Temas
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Descripción / Temas a repasar',
                        hintText: 'Capítulos 1 al 4, diseño responsivo...',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Configuración de Notificaciones (H30)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Notificación / Alarma'),
                      subtitle: Text(
                        notificar
                            ? 'Alarma $antelacionHoras horas antes de la evaluación'
                            : 'Sin notificaciones locales',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: notificar,
                      onChanged: (val) {
                        setDialogState(() => notificar = val);
                      },
                      secondary: Icon(
                        notificar
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_outlined,
                        color: notificar ? scheme.primary : scheme.outline,
                      ),
                    ),
                    if (notificar) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: antelacionHoras,
                        decoration: const InputDecoration(
                          labelText: 'Antelación de la notificación',
                          prefixIcon: Icon(Icons.timer_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 1, child: Text('1 hora antes')),
                          DropdownMenuItem(
                              value: 2, child: Text('2 horas antes')),
                          DropdownMenuItem(
                              value: 12, child: Text('12 horas antes')),
                          DropdownMenuItem(
                              value: 24,
                              child: Text('24 horas antes (Recomendado)')),
                          DropdownMenuItem(
                              value: 48, child: Text('2 días antes')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => antelacionHoras = val);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(dialogCtx).pop(true);
                  }
                },
                child: Text(esEdicion ? 'Guardar' : 'Crear'),
              ),
            ],
          );
        },
      ),
    );

    if (resultado == true) {
      final nombreFinal = cursoSeleccionadoNombre.trim().isNotEmpty
          ? cursoSeleccionadoNombre.trim()
          : (cursoTextoCtrl.text.trim().isNotEmpty
              ? cursoTextoCtrl.text.trim()
              : 'General');

      try {
        if (esEdicion) {
          await _service.actualizarRecordatorio(
            uid: _uid,
            id: existente.id,
            titulo: tituloCtrl.text.trim(),
            cursoId: cursoSeleccionadoId,
            cursoNombre: nombreFinal,
            fecha: fechaSeleccionada,
            descripcion: descCtrl.text.trim(),
            notificar: notificar,
            antelacionHoras: antelacionHoras,
          );
          if (mounted) _mostrarMensaje('Recordatorio actualizado.');
        } else {
          await _service.crearRecordatorio(
            uid: _uid,
            titulo: tituloCtrl.text.trim(),
            cursoId: cursoSeleccionadoId,
            cursoNombre: nombreFinal,
            fecha: fechaSeleccionada,
            descripcion: descCtrl.text.trim(),
            notificar: notificar,
            antelacionHoras: antelacionHoras,
          );
          if (mounted) _mostrarMensaje('Recordatorio creado.');
        }
      } catch (e) {
        if (mounted) _mostrarMensaje('No se pudo guardar el recordatorio.');
      }
    }
  }

  Future<void> _eliminarRecordatorio(RecordatorioEvaluacion r) async {
    final confirmar = await confirmarEliminar(
      context,
      titulo: 'Eliminar recordatorio',
      mensaje: '¿Deseas eliminar el recordatorio de "${r.titulo}"?',
    );
    if (!confirmar) return;

    try {
      await _service.eliminarRecordatorio(_uid, r.id);
      if (mounted) _mostrarMensaje('Recordatorio eliminado.');
    } catch (_) {
      if (mounted) _mostrarMensaje('No se pudo eliminar el recordatorio.');
    }
  }

  Future<void> _alternarEstado(RecordatorioEvaluacion r) async {
    try {
      await _service.cambiarEstadoCompletado(_uid, r.id, !r.completado);
      if (mounted) {
        _mostrarMensaje(r.completado
            ? 'Marcado como pendiente.'
            : '¡Evaluación marcada como rendida!');
      }
    } catch (_) {
      if (mounted) _mostrarMensaje('No se pudo actualizar el estado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = _recordatoriosStream;

    return Scaffold(
      appBar: AppBarNivel(
        padre: widget.cursoNombre != null
            ? 'Curso: ${widget.cursoNombre}'
            : 'Planificación académica',
        titulo: 'Recordatorios de evaluaciones',
        acciones: [
          IconButton(
            icon: const Icon(Icons.add_alert_rounded),
            tooltip: 'Nuevo recordatorio',
            onPressed: () => _crearOEditarRecordatorio(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: const Text('Recordatorio'),
        onPressed: () => _crearOEditarRecordatorio(),
      ),
      body: Column(
        children: [
          // Segmented filter buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SegmentedButton<FiltroRecordatorios>(
              segments: const [
                ButtonSegment(
                  value: FiltroRecordatorios.pendientes,
                  label: Text('Pendientes'),
                  icon: Icon(Icons.schedule_rounded, size: 18),
                ),
                ButtonSegment(
                  value: FiltroRecordatorios.todos,
                  label: Text('Todos'),
                  icon: Icon(Icons.list_alt_rounded, size: 18),
                ),
                ButtonSegment(
                  value: FiltroRecordatorios.rendidas,
                  label: Text('Rendidas'),
                  icon: Icon(Icons.check_circle_outline_rounded, size: 18),
                ),
              ],
              selected: {_filtro},
              onSelectionChanged: (nueva) {
                setState(() => _filtro = nueva.first);
              },
            ),
          ),

          // Lista de recordatorios
          Expanded(
            child: StreamBuilder<List<RecordatorioEvaluacion>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Error al cargar recordatorios.'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final todos = snapshot.data!;
                final filtrados = todos.where((r) {
                  switch (_filtro) {
                    case FiltroRecordatorios.pendientes:
                      return !r.completado;
                    case FiltroRecordatorios.rendidas:
                      return r.completado;
                    case FiltroRecordatorios.todos:
                      return true;
                  }
                }).toList();

                if (filtrados.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: EstadoVacio(
                        icono: Icons.event_available_rounded,
                        titulo: _filtro == FiltroRecordatorios.pendientes
                            ? '¡Estás al día!'
                            : 'Sin recordatorios',
                        texto: _filtro == FiltroRecordatorios.pendientes
                            ? 'No tienes evaluaciones pendientes programadas.'
                            : 'Presiona el botón para agregar una nueva fecha de evaluación.',
                        textoBoton: 'Nuevo recordatorio',
                        onPressed: () => _crearOEditarRecordatorio(),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final item = filtrados[index];
                    return _TarjetaRecordatorio(
                      recordatorio: item,
                      onToggleCompletado: () => _alternarEstado(item),
                      onEditar: () =>
                          _crearOEditarRecordatorio(existente: item),
                      onEliminar: () => _eliminarRecordatorio(item),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaRecordatorio extends StatelessWidget {
  final RecordatorioEvaluacion recordatorio;
  final VoidCallback onToggleCompletado;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _TarjetaRecordatorio({
    required this.recordatorio,
    required this.onToggleCompletado,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final r = recordatorio;

    // Colores según estado del recordatorio
    Color chipFondo;
    Color chipTexto;
    IconData chipIcono;

    if (r.completado) {
      chipFondo = scheme.surfaceContainerHigh;
      chipTexto = scheme.onSurfaceVariant;
      chipIcono = Icons.check_circle_rounded;
    } else if (r.estaVencido) {
      chipFondo = scheme.errorContainer;
      chipTexto = scheme.onErrorContainer;
      chipIcono = Icons.warning_amber_rounded;
    } else if (r.esHoy) {
      chipFondo = Colors.amber.withValues(alpha: 0.25);
      chipTexto = Colors.amber.shade900;
      chipIcono = Icons.today_rounded;
    } else if (r.esManana) {
      chipFondo = scheme.secondaryContainer;
      chipTexto = scheme.onSecondaryContainer;
      chipIcono = Icons.event_rounded;
    } else {
      chipFondo = scheme.primaryContainer;
      chipTexto = scheme.onPrimaryContainer;
      chipIcono = Icons.schedule_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: r.estaVencido && !r.completado
              ? scheme.error.withValues(alpha: 0.4)
              : scheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEditar,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: Curso + Chip de estado + Menú
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.cursoNombre,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          r.titulo,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: r.completado
                                ? TextDecoration.lineThrough
                                : null,
                            color: r.completado
                                ? scheme.onSurfaceVariant
                                : scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Chip de tiempo restante
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: chipFondo,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(chipIcono, size: 14, color: chipTexto),
                        const SizedBox(width: 4),
                        Text(
                          r.tiempoRestanteTexto,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: chipTexto,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Opciones
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    tooltip: 'Opciones',
                    onPressed: () {
                      mostrarOpciones(
                        context,
                        titulo: r.titulo,
                        opciones: [
                          OpcionMenu(
                            icono: r.completado
                                ? Icons.undo_rounded
                                : Icons.check_circle_outline_rounded,
                            texto: r.completado
                                ? 'Marcar como pendiente'
                                : 'Marcar como rendida',
                            onTap: onToggleCompletado,
                          ),
                          OpcionMenu(
                            icono: Icons.edit_outlined,
                            texto: 'Editar recordatorio',
                            onTap: onEditar,
                          ),
                          OpcionMenu(
                            icono: Icons.delete_outline_rounded,
                            texto: 'Eliminar recordatorio',
                            onTap: onEliminar,
                            destructiva: true,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Fecha y hora
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    r.fechaFormateada,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (r.notificar && !r.completado) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.notifications_active_outlined,
                      size: 14,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${r.antelacionHoras}h antes',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),

              // Descripción si existe
              if (r.descripcion.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  r.descripcion,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
