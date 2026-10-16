import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/nota.dart';
import '../models/tipo_evaluacion.dart';
import '../models/unidad.dart';
import '../services/calculos_multinivel.dart';
import '../services/escaner_notas.dart';
import '../services/importacion_notas_service.dart';
import '../services/lector_reporte_notas.dart';
import '../theme/app_theme.dart';
import '../theme/estado_nota_colors.dart';
import '../utils/formato_nota.dart';
import '../widgets/app_bar_nivel.dart';
import '../widgets/boton_punteado.dart';
import '../widgets/card_resultado.dart';
import '../widgets/linea_pesos.dart';
import '../widgets/seccion_titulo.dart';

/// H19 - Registro de notas por camara desde el reporte del portal.
///
/// Flujo: instrucciones -> foto o galeria -> lectura en el dispositivo ->
/// vista previa editable -> guardar. Nada se guarda sin confirmar.
/// Devuelve el id del curso guardado (o null si se cancela).
class EscanearNotasScreen extends StatefulWidget {
  final String cicloId;
  final String cicloNombre;

  const EscanearNotasScreen({super.key, required this.cicloId, required this.cicloNombre});

  @override
  State<EscanearNotasScreen> createState() => _EscanearNotasScreenState();
}

enum _Fase { inicio, leyendo, revision, guardando }

class _EscanearNotasScreenState extends State<EscanearNotasScreen> {
  final EscanerNotas _escaner = EscanerNotas();
  final ImportacionNotasService _importacion = ImportacionNotasService();

  _Fase _fase = _Fase.inicio;
  String? _error;

  final _cursoCtrl = TextEditingController();
  final List<_UnidadEditable> _unidades = [];

  @override
  void dispose() {
    _cursoCtrl.dispose();
    for (final u in _unidades) {
      u.dispose();
    }
    super.dispose();
  }

  void _refrescar() => setState(() {});

  // --- Lectura ---

  Future<void> _escanear(OrigenImagen origen) async {
    setState(() {
      _fase = _Fase.leyendo;
      _error = null;
    });
    try {
      final reporte = await _escaner.escanear(origen);
      if (!mounted) return;
      if (reporte == null) {
        setState(() => _fase = _Fase.inicio); // cancelo la camara o la galeria
        return;
      }
      if (reporte.vacio) {
        setState(() {
          _fase = _Fase.inicio;
          _error = 'No encontramos una tabla de notas en la imagen. Asegúrate de que se vean '
              'los encabezados (Unidad, Criterio, Peso C., Peso U., Nota) y que la foto esté recta y nítida.';
        });
        HapticFeedback.mediumImpact();
        return;
      }
      _cargarReporte(reporte);
      HapticFeedback.lightImpact();
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _fase = _Fase.inicio;
        _error = e.code == 'camera_access_denied' || e.code == 'photo_access_denied'
            ? 'Pondera necesita permiso para usar la cámara o la galería. Actívalo en los ajustes del teléfono.'
            : 'No pudimos leer la imagen. Inténtalo de nuevo.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _fase = _Fase.inicio;
        _error = 'No pudimos leer la imagen. Inténtalo de nuevo.';
      });
    }
  }

  void _cargarReporte(ReporteDetectado reporte) {
    final anteriores = List.of(_unidades);
    _liberarDespues(() {
      for (final u in anteriores) {
        u.dispose();
      }
    });
    _unidades
      ..clear()
      ..addAll(reporte.unidades.map((u) => _UnidadEditable.desde(u, _refrescar)));
    _cursoCtrl.text = _formatearCurso(reporte.curso ?? '');
    setState(() => _fase = _Fase.revision);
  }

  /// "TALLER DE TESIS II" -> "Taller de Tesis II" (respeta numeros romanos).
  static String _formatearCurso(String nombre) {
    const menores = {'de', 'del', 'la', 'las', 'el', 'los', 'y', 'e', 'en', 'a', 'para', 'por'};
    final palabras = nombre.trim().split(RegExp(r'\s+'));
    return [
      for (var i = 0; i < palabras.length; i++)
        () {
          final p = palabras[i];
          if (p.isEmpty) return p;
          if (RegExp(r'^[IVXL]+$').hasMatch(p) || p == '/') return p;
          final minuscula = p.toLowerCase();
          if (i > 0 && menores.contains(minuscula)) return minuscula;
          return minuscula[0].toUpperCase() + minuscula.substring(1);
        }(),
    ].join(' ');
  }

  // --- Validacion y vista previa del calculo ---

  List<String> get _errores {
    final errores = <String>[];
    if (_cursoCtrl.text.trim().isEmpty) errores.add('Escribe el nombre del curso.');
    if (_unidades.isEmpty) errores.add('Agrega al menos una unidad.');
    for (final u in _unidades) {
      final nombre = u.nombre.text.trim().isEmpty ? 'Una unidad' : u.nombre.text.trim();
      if (u.nombre.text.trim().isEmpty) errores.add('Hay una unidad sin nombre.');
      if (!_pesoValido(u.peso.text)) errores.add('$nombre: el peso debe ser mayor que 0 y hasta 100.');
      for (final c in u.criterios) {
        if (!_pesoValido(c.peso.text)) {
          errores.add('$nombre: "${c.etiqueta}" necesita un peso mayor que 0 y hasta 100.');
        }
        if (c.nota.text.trim().isNotEmpty && !_notaValida(c.nota.text)) {
          errores.add('$nombre: la nota de "${c.etiqueta}" debe estar entre 0 y 20.');
        }
      }
    }
    return errores;
  }

  static double? _leer(String t) => double.tryParse(t.trim().replaceAll(',', '.'));
  static bool _pesoValido(String t) {
    final v = _leer(t);
    return v != null && v > 0 && v <= 100;
  }

  static bool _notaValida(String t) {
    final v = _leer(t);
    return v != null && v >= 0 && v <= 20;
  }

  /// Usa la logica de H14 para mostrar como quedaria el curso.
  ResultadoCalculoCurso _vistaPrevia() {
    return CalculosMultinivel.calcular([
      for (var i = 0; i < _unidades.length; i++)
        EstructuraUnidad(
          unidad: Unidad(
            id: 'u$i',
            nombre: _unidades[i].nombre.text,
            cursoId: '',
            porcentaje: _leer(_unidades[i].peso.text) ?? 0,
          ),
          tipos: [
            for (var j = 0; j < _unidades[i].criterios.length; j++)
              () {
                final c = _unidades[i].criterios[j];
                final nota = _notaValida(c.nota.text) ? _leer(c.nota.text) : null;
                return EstructuraTipoEvaluacion(
                  tipo: TipoEvaluacion(id: 't$i$j', nombre: c.etiqueta, porcentaje: _leer(c.peso.text) ?? 0),
                  notas: nota == null ? [] : [Nota(id: 'n$i$j', valor: nota, tipoEvaluacionId: 't$i$j')],
                );
              }(),
          ],
        ),
    ]);
  }

  // --- Guardar ---

  Future<void> _guardar() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _errores.isNotEmpty) return;
    final nombreCurso = _cursoCtrl.text.trim();

    setState(() => _fase = _Fase.guardando);
    try {
      // Criterio 7: si el curso ya existe en el ciclo, ofrecer actualizarlo.
      final existente = await _importacion.buscarCursoExistente(uid, widget.cicloId, nombreCurso);
      String? reemplazarId;
      if (existente != null) {
        if (!mounted) return;
        final decision = await _preguntarCursoExistente(existente.nombre);
        if (decision == null) {
          setState(() => _fase = _Fase.revision);
          return;
        }
        reemplazarId = decision ? existente.id : null;
      }

      final cursoId = await _importacion.guardar(
        uid: uid,
        cicloId: widget.cicloId,
        nombreCurso: nombreCurso,
        unidades: [for (final u in _unidades) u.aDetectada()],
        reemplazarCursoId: reemplazarId,
      );
      if (!mounted) return;
      final notas = _unidades.fold<int>(0, (a, u) => a + u.criterios.where((c) => c.nota.text.trim().isNotEmpty).length);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$nombreCurso guardado · $notas ${notas == 1 ? 'nota' : 'notas'} registradas.')),
      );
      Navigator.of(context).pop(cursoId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _fase = _Fase.revision);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar. Revisa tu conexión e inténtalo de nuevo.')),
      );
    }
  }

  /// true = actualizar el existente, false = crear otro, null = cancelar.
  Future<bool?> _preguntarCursoExistente(String nombre) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.sync_rounded, color: Theme.of(dialogContext).colorScheme.primary),
        title: const Text('Este curso ya existe'),
        content: Text(
          '"$nombre" ya está en ${widget.cicloNombre}. Puedes actualizarlo con las notas del reporte '
          '(se reemplazan sus unidades y notas) o guardarlo como un curso nuevo.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Crear otro')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Actualizar')),
        ],
      ),
    );
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    final enRevision = _fase == _Fase.revision || _fase == _Fase.guardando;
    return PopScope(
      canPop: !enRevision,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final salir = await _confirmarDescartar();
        if (salir && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBarNivel(
          padre: widget.cicloNombre,
          titulo: enRevision ? 'Revisa las notas' : 'Escanear notas',
          acciones: [
            if (enRevision)
              IconButton(
                icon: const Icon(Icons.document_scanner_rounded),
                tooltip: 'Escanear otra vez',
                onPressed: _fase == _Fase.guardando ? null : () => setState(() => _fase = _Fase.inicio),
              ),
          ],
        ),
        body: switch (_fase) {
          _Fase.inicio => _inicio(context),
          _Fase.leyendo => const _Leyendo(),
          _Fase.revision || _Fase.guardando => _revision(context),
        },
        bottomNavigationBar: enRevision ? _barraGuardar(context) : null,
      ),
    );
  }

  Future<bool> _confirmarDescartar() async {
    final r = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Descartar lo escaneado?'),
        content: const Text('Las notas leídas no se guardarán.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Seguir revisando')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Descartar')),
        ],
      ),
    );
    return r == true;
  }

  Widget _inicio(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final estado = EstadoNotaColors.of(context);

    if (!EscanerNotas.disponible) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.phonelink_off_rounded, size: 56, color: scheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('Disponible en la app del celular', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'El escaneo de notas usa la cámara y el reconocimiento de texto del teléfono (Android). '
            'En esta versión puedes registrar las notas manualmente.',
            style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Registrar manualmente')),
        ],
      );
    }

    Widget consejo(IconData icono, String texto) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(icono, size: 22, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(texto, style: const TextStyle(fontSize: 15))),
            ],
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(28)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(18)),
                child: Icon(Icons.document_scanner_rounded, color: scheme.onPrimary, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                'Escanea tu reporte de notas',
                style: theme.textTheme.headlineSmall?.copyWith(color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: 6),
              Text(
                'Toma una foto o una captura del reporte del portal. Pondera lee el curso, las '
                'unidades, los pesos y tus notas; tú revisas todo antes de guardar.',
                style: TextStyle(fontSize: 15, height: 1.4, color: scheme.onPrimaryContainer),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: estado.avisoFondo, borderRadius: BorderRadius.circular(20)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_rounded, color: estado.onAvisoFondo),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_error!, style: TextStyle(fontSize: 15, height: 1.35, color: estado.onAvisoFondo)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        const SeccionTitulo('Para una buena lectura'),
        const SizedBox(height: 12),
        consejo(Icons.crop_free_rounded, 'Encuadra solo la tabla de un curso, de frente y sin inclinarla.'),
        consejo(Icons.wb_sunny_rounded, 'Usa buena luz y evita reflejos en la pantalla.'),
        consejo(Icons.table_rows_rounded, 'Que se vean los encabezados: Unidad, Criterio, Peso C., Peso U. y Nota.'),
        consejo(Icons.screenshot_rounded, 'Una captura de pantalla del portal da el mejor resultado.'),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => _escanear(OrigenImagen.camara),
          icon: const Icon(Icons.photo_camera_rounded),
          label: const Text('Tomar foto'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _escanear(OrigenImagen.galeria),
          icon: const Icon(Icons.photo_library_rounded),
          label: const Text('Elegir captura o foto'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.lock_rounded, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'La imagen se procesa en tu teléfono, no se envía a ningún servidor y no se guarda.',
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _revision(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final estado = EstadoNotaColors.of(context);
    final resultado = _vistaPrevia();
    final errores = _errores;
    final totalUnidades = _unidades.fold<double>(0, (a, u) => a + (_leer(u.peso.text) ?? 0));
    final bloqueado = _fase == _Fase.guardando;

    return AbsorbPointer(
      absorbing: bloqueado,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          CardResultado(
            nota: resultado.notaActual,
            titulo: resultado.estado == EstadoCalculoCurso.completo ? 'Nota final del curso' : 'Promedio parcial',
            subtitulo: resultado.notaActual == null
                ? 'Sin notas en el reporte'
                : '${FormatoNota.porcentaje(resultado.porcentajeEvaluado)}% del curso evaluado',
          ),
          const SizedBox(height: 14),
          if (errores.isNotEmpty)
            _Aviso(
              fondo: estado.desaprobadoFondo,
              texto: estado.onDesaprobadoFondo,
              icono: Icons.error_rounded,
              color: estado.desaprobado,
              titulo: 'Corrige antes de guardar',
              lineas: errores.take(4).toList(),
            )
          else
            _Aviso(
              fondo: scheme.surfaceContainerHigh,
              texto: scheme.onSurface,
              icono: Icons.fact_check_rounded,
              color: scheme.primary,
              titulo: 'Revisa lo leído',
              lineas: const ['Toca cualquier valor para corregirlo. Las notas vacías quedan como pendientes.'],
            ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Curso', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          TextField(
            controller: _cursoCtrl,
            onChanged: (_) => _refrescar(),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.menu_book_rounded), hintText: 'Nombre del curso'),
          ),
          const SizedBox(height: 22),
          SeccionTitulo(
            'Unidades · ${_unidades.length}',
            trailing: LineaPesos(suma: totalUnidades, compacta: true),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < _unidades.length; i++) ...[
            _TarjetaUnidadEditable(
              key: ObjectKey(_unidades[i]),
              unidad: _unidades[i],
              onCambio: _refrescar,
              onEliminar: () {
                final quitada = _unidades.removeAt(i);
                _refrescar();
                _liberarDespues(quitada.dispose);
              },
            ),
            const SizedBox(height: 12),
          ],
          BotonPunteado(
            texto: 'Agregar unidad',
            onPressed: () => setState(
              () => _unidades.add(_UnidadEditable.desde(
                UnidadDetectada(nombre: 'Unidad ${_unidades.length + 1}', criterios: [CriterioDetectado(nombre: 'Evaluacion 01')]),
                _refrescar,
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barraGuardar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final guardando = _fase == _Fase.guardando;
    final puede = _errores.isEmpty && !guardando;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: FilledButton.icon(
            onPressed: puede ? _guardar : null,
            icon: guardando
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Icon(Icons.save_rounded),
            label: Text(guardando ? 'Guardando…' : 'Guardar curso y notas'),
          ),
        ),
      ),
    );
  }
}

/// Libera controladores en el siguiente frame, cuando sus campos ya no estan en pantalla.
void _liberarDespues(VoidCallback liberar) => WidgetsBinding.instance.addPostFrameCallback((_) => liberar());

// --- Modelo editable de la vista previa ---

class _CriterioEditable {
  final String nombre;
  final TextEditingController descripcion;
  final TextEditingController peso;
  final TextEditingController nota;

  _CriterioEditable(CriterioDetectado c, VoidCallback onCambio)
      : nombre = c.nombre,
        descripcion = TextEditingController(text: c.descripcion),
        peso = TextEditingController(text: c.peso == null ? '' : FormatoNota.porcentaje(c.peso!)),
        nota = TextEditingController(text: c.nota == null ? '' : _formatear(c.nota!)) {
    for (final ctrl in [descripcion, peso, nota]) {
      ctrl.addListener(onCambio);
    }
  }

  static String _formatear(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  String get etiqueta => descripcion.text.trim().isEmpty ? nombre : descripcion.text.trim();

  CriterioDetectado aDetectado() => CriterioDetectado(
        nombre: nombre,
        descripcion: descripcion.text.trim(),
        peso: double.tryParse(peso.text.trim().replaceAll(',', '.')),
        nota: nota.text.trim().isEmpty ? null : double.tryParse(nota.text.trim().replaceAll(',', '.')),
      );

  void dispose() {
    descripcion.dispose();
    peso.dispose();
    nota.dispose();
  }
}

class _UnidadEditable {
  final TextEditingController nombre;
  final TextEditingController peso;
  final List<_CriterioEditable> criterios;
  final VoidCallback onCambio;

  _UnidadEditable._(this.nombre, this.peso, this.criterios, this.onCambio);

  factory _UnidadEditable.desde(UnidadDetectada u, VoidCallback onCambio) {
    final nombre = TextEditingController(text: u.nombre)..addListener(onCambio);
    final peso = TextEditingController(text: u.peso == null ? '' : FormatoNota.porcentaje(u.peso!))..addListener(onCambio);
    return _UnidadEditable._(nombre, peso, [for (final c in u.criterios) _CriterioEditable(c, onCambio)], onCambio);
  }

  void agregarCriterio() => criterios.add(_CriterioEditable(
        CriterioDetectado(nombre: 'Evaluacion ${(criterios.length + 1).toString().padLeft(2, '0')}'),
        onCambio,
      ));

  UnidadDetectada aDetectada() => UnidadDetectada(
        nombre: nombre.text.trim(),
        peso: double.tryParse(peso.text.trim().replaceAll(',', '.')),
        criterios: [for (final c in criterios) c.aDetectado()],
      );

  void dispose() {
    nombre.dispose();
    peso.dispose();
    for (final c in criterios) {
      c.dispose();
    }
  }
}

// --- Widgets de la vista previa ---

class _TarjetaUnidadEditable extends StatelessWidget {
  final _UnidadEditable unidad;
  final VoidCallback onCambio;
  final VoidCallback onEliminar;

  const _TarjetaUnidadEditable({super.key, required this.unidad, required this.onCambio, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final suma = unidad.criterios.fold<double>(0, (a, c) => a + (double.tryParse(c.peso.text.replaceAll(',', '.')) ?? 0));

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 6, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _Campo(controller: unidad.nombre, hint: 'Unidad', negrita: true)),
                const SizedBox(width: 8),
                SizedBox(width: 84, child: _Campo(controller: unidad.peso, hint: 'Peso', sufijo: '%', numerico: true, rango: 100)),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: scheme.onSurfaceVariant,
                  tooltip: 'Quitar unidad',
                  onPressed: onEliminar,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Criterio', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
                  ),
                  LineaPesos(suma: suma, compacta: true),
                ],
              ),
            ),
            const SizedBox(height: 6),
            for (var j = 0; j < unidad.criterios.length; j++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: _Campo(controller: unidad.criterios[j].descripcion, hint: unidad.criterios[j].nombre)),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 64,
                      child: _Campo(controller: unidad.criterios[j].peso, hint: '%', sufijo: '%', numerico: true, rango: 100),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 64,
                      child: _Campo(controller: unidad.criterios[j].nota, hint: '—', numerico: true, rango: 20, esNota: true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: scheme.onSurfaceVariant,
                      tooltip: 'Quitar ${unidad.criterios[j].etiqueta}',
                      onPressed: () {
                        final quitado = unidad.criterios.removeAt(j);
                        onCambio();
                        _liberarDespues(quitado.dispose);
                      },
                    ),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed: () {
                unidad.agregarCriterio();
                onCambio();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Criterio'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? sufijo;
  final bool numerico;
  final bool negrita;
  final bool esNota;

  /// Valor maximo permitido (100 para pesos, 20 para notas).
  final double? rango;

  const _Campo({
    required this.controller,
    required this.hint,
    this.sufijo,
    this.numerico = false,
    this.negrita = false,
    this.esNota = false,
    this.rango,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final estado = EstadoNotaColors.of(context);
    final texto = controller.text.trim();
    final valor = double.tryParse(texto.replaceAll(',', '.'));
    final invalido = numerico && texto.isNotEmpty && (valor == null || valor < 0 || (rango != null && valor > rango!));

    OutlineInputBorder borde(Color c, double w) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c, width: w));

    final colorTexto = esNota && !invalido ? estado.colorDeNota(valor, scheme.onSurface) : null;

    return TextField(
      controller: controller,
      textAlign: numerico ? TextAlign.center : TextAlign.start,
      keyboardType: numerico ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      inputFormatters: numerico ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*'))] : null,
      style: esNota
          ? AppTheme.estiloNota(17, color: colorTexto)
          : TextStyle(fontSize: 15, fontWeight: negrita ? FontWeight.w700 : FontWeight.w400),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        suffixText: numerico && sufijo != null && texto.isNotEmpty ? sufijo : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        enabledBorder: invalido ? borde(scheme.error, 2) : borde(scheme.outline, 1),
        focusedBorder: invalido ? borde(scheme.error, 2) : borde(scheme.primary, 2),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  final Color fondo;
  final Color texto;
  final Color color;
  final IconData icono;
  final String titulo;
  final List<String> lineas;

  const _Aviso({
    required this.fondo,
    required this.texto,
    required this.color,
    required this.icono,
    required this.titulo,
    required this.lineas,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(20)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: texto)),
                  const SizedBox(height: 4),
                  for (final l in lineas)
                    Text(l, style: TextStyle(fontSize: 14, height: 1.35, color: texto)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Leyendo extends StatelessWidget {
  const _Leyendo();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 44, height: 44, child: CircularProgressIndicator(strokeWidth: 3.5)),
          const SizedBox(height: 20),
          Text('Leyendo el reporte…', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Esto toma unos segundos', style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
