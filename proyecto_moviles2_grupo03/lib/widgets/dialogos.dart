import 'package:flutter/material.dart';
import '../utils/formato_nota.dart';

/// Resultado de [pedirNombreYPeso].
typedef NombrePeso = ({String nombre, double peso});

/// Resultado de [pedirNombreYCreditos] (H21).
typedef NombreCreditos = ({String nombre, int creditos});

/// Opcion de [mostrarOpciones].
class OpcionMenu {
  final IconData icono;
  final String texto;
  final VoidCallback onTap;
  final bool destructiva;

  const OpcionMenu({
    required this.icono,
    required this.texto,
    required this.onTap,
    this.destructiva = false,
  });
}

double? _leerNumero(String? texto) => double.tryParse((texto ?? '').trim().replaceAll(',', '.'));

/// Pide nombre y créditos para un curso (H21).
Future<NombreCreditos?> pedirNombreYCreditos(
  BuildContext context, {
  required String titulo,
  required String etiquetaNombre,
  required String hintNombre,
  String inicialNombre = '',
  int inicialCreditos = 3,
  required String textoBoton,
}) {
  return showDialog<NombreCreditos>(
    context: context,
    builder: (_) => _DialogoNombreCreditos(
      titulo: titulo,
      etiquetaNombre: etiquetaNombre,
      hintNombre: hintNombre,
      inicialNombre: inicialNombre,
      inicialCreditos: inicialCreditos,
      textoBoton: textoBoton,
    ),
  );
}

/// Pide un nombre (crear o renombrar ciclo / curso).
Future<String?> pedirNombre(
  BuildContext context, {
  required String titulo,
  required String etiqueta,
  required String hint,
  String inicial = '',
  required String textoBoton,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _DialogoNombrePeso(
      titulo: titulo,
      etiquetaNombre: etiqueta,
      hintNombre: hint,
      inicialNombre: inicial,
      textoBoton: textoBoton,
      conPeso: false,
    ),
  ).then((r) => r is String ? r : null);
}

/// Pide nombre y peso (%) para una unidad o un tipo de evaluacion.
/// [pesoDisponible] se muestra como ayuda ("Disponible: 35%").
Future<NombrePeso?> pedirNombreYPeso(
  BuildContext context, {
  required String titulo,
  required String etiquetaNombre,
  required String hintNombre,
  String inicialNombre = '',
  double? inicialPeso,
  double? pesoDisponible,
  required String textoBoton,
}) {
  return showDialog<Object>(
    context: context,
    builder: (_) => _DialogoNombrePeso(
      titulo: titulo,
      etiquetaNombre: etiquetaNombre,
      hintNombre: hintNombre,
      inicialNombre: inicialNombre,
      inicialPeso: inicialPeso,
      pesoDisponible: pesoDisponible,
      textoBoton: textoBoton,
      conPeso: true,
    ),
  ).then((r) => r is NombrePeso ? r : null);
}

class _DialogoNombrePeso extends StatefulWidget {
  final String titulo;
  final String etiquetaNombre;
  final String hintNombre;
  final String inicialNombre;
  final double? inicialPeso;
  final double? pesoDisponible;
  final String textoBoton;
  final bool conPeso;

  const _DialogoNombrePeso({
    required this.titulo,
    required this.etiquetaNombre,
    required this.hintNombre,
    required this.inicialNombre,
    this.inicialPeso,
    this.pesoDisponible,
    required this.textoBoton,
    required this.conPeso,
  });

  @override
  State<_DialogoNombrePeso> createState() => _DialogoNombrePesoState();
}

class _DialogoNombrePesoState extends State<_DialogoNombrePeso> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreCtrl = TextEditingController(text: widget.inicialNombre);
  late final _pesoCtrl = TextEditingController(
    text: widget.inicialPeso == null ? '' : FormatoNota.porcentaje(widget.inicialPeso!),
  );

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _pesoCtrl.dispose();
    super.dispose();
  }

  void _aceptar() {
    if (!_formKey.currentState!.validate()) return;
    final nombre = _nombreCtrl.text.trim();
    if (widget.conPeso) {
      Navigator.of(context).pop<Object>((nombre: nombre, peso: _leerNumero(_pesoCtrl.text)!));
    } else {
      Navigator.of(context).pop<Object>(nombre);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disponible = widget.pesoDisponible;
    return AlertDialog(
      title: Text(widget.titulo),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nombreCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: widget.conPeso ? TextInputAction.next : TextInputAction.done,
              onFieldSubmitted: widget.conPeso ? null : (_) => _aceptar(),
              decoration: InputDecoration(labelText: widget.etiquetaNombre, hintText: widget.hintNombre),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Escribe un nombre' : null,
            ),
            if (widget.conPeso) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _pesoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _aceptar(),
                decoration: InputDecoration(
                  labelText: 'Peso',
                  suffixText: '%',
                  prefixIcon: const Icon(Icons.percent_rounded),
                  helperText: disponible == null
                      ? null
                      : 'Disponible: ${FormatoNota.porcentaje(disponible.clamp(0, 100).toDouble())}%',
                ),
                validator: (v) {
                  final n = _leerNumero(v);
                  if (n == null || !n.isFinite || n <= 0 || n > 100) {
                    return 'Ingresa un valor mayor que 0 y hasta 100';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _aceptar, child: Text(widget.textoBoton)),
      ],
    );
  }
}

/// Confirma una eliminacion con un boton rojo. Devuelve true si se confirma.
Future<bool> confirmarEliminar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final r = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  return r == true;
}

/// Hoja inferior con opciones (editar, eliminar...) para una tarjeta.
Future<void> mostrarOpciones(
  BuildContext context, {
  required String titulo,
  required List<OpcionMenu> opciones,
}) {
  final scheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: scheme.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(titulo, style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final o in opciones)
              ListTile(
                minTileHeight: 56,
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Icon(o.icono, color: o.destructiva ? scheme.error : scheme.onSurfaceVariant),
                title: Text(
                  o.texto,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: o.destructiva ? scheme.error : scheme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  o.onTap();
                },
              ),
          ],
        ),
      ),
    ),
  );
}

class _DialogoNombreCreditos extends StatefulWidget {
  final String titulo;
  final String etiquetaNombre;
  final String hintNombre;
  final String inicialNombre;
  final int inicialCreditos;
  final String textoBoton;

  const _DialogoNombreCreditos({
    required this.titulo,
    required this.etiquetaNombre,
    required this.hintNombre,
    required this.inicialNombre,
    required this.inicialCreditos,
    required this.textoBoton,
  });

  @override
  State<_DialogoNombreCreditos> createState() => _DialogoNombreCreditosState();
}

class _DialogoNombreCreditosState extends State<_DialogoNombreCreditos> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreCtrl = TextEditingController(text: widget.inicialNombre);
  late final _creditosCtrl =
      TextEditingController(text: widget.inicialCreditos.toString());

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _creditosCtrl.dispose();
    super.dispose();
  }

  void _aceptar() {
    if (!_formKey.currentState!.validate()) return;
    final nombre = _nombreCtrl.text.trim();
    final creditos = int.tryParse(_creditosCtrl.text.trim()) ?? 3;
    Navigator.of(context)
        .pop<NombreCreditos>((nombre: nombre, creditos: creditos));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nombreCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: widget.etiquetaNombre,
                hintText: widget.hintNombre,
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Escribe un nombre' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _creditosCtrl,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _aceptar(),
              decoration: const InputDecoration(
                labelText: 'Créditos del curso',
                helperText: 'Valor entre 1 y 10 créditos (por defecto 3)',
                prefixIcon: Icon(Icons.school_outlined),
                suffixText: 'cr.',
              ),
              validator: (v) {
                final c = int.tryParse((v ?? '').trim());
                if (c == null || c < 1 || c > 10) {
                  return 'Ingresa un valor entre 1 y 10 créditos';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _aceptar,
          child: Text(widget.textoBoton),
        ),
      ],
    );
  }
}
