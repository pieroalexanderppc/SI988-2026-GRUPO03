import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/componente_evaluacion.dart';
import '../providers/componentes_provider.dart';

/// Widget reutilizable que representa una fila editable de un componente de evaluación.
class FilaComponente extends StatefulWidget {
  final ComponenteEvaluacion componente;
  final bool puedeEliminar;

  const FilaComponente({
    required super.key,
    required this.componente,
    required this.puedeEliminar,
  });

  @override
  State<FilaComponente> createState() => _FilaComponenteState();
}

class _FilaComponenteState extends State<FilaComponente> {
  late TextEditingController _nombreController;
  late TextEditingController _notaController;
  late TextEditingController _pesoController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.componente.nombre);
    _notaController = TextEditingController(
      text: widget.componente.nota == 0.0 && widget.componente.nombre.isEmpty
          ? ''
          : widget.componente.nota.toString(),
    );
    _pesoController = TextEditingController(
      text: widget.componente.peso == 0.0 && widget.componente.nombre.isEmpty
          ? ''
          : widget.componente.peso.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant FilaComponente oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sincronizar controladores si el modelo cambia desde fuera (sin romper edición activa)
    if (oldWidget.componente.nombre != widget.componente.nombre &&
        _nombreController.text != widget.componente.nombre) {
      _nombreController.text = widget.componente.nombre;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _notaController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ComponentesProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                // Campo para el nombre del componente (ej. Examen Parcial)
                Expanded(
                  child: TextField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del componente',
                      hintText: 'Ej. Examen Parcial',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      provider.actualizarComponente(
                        widget.componente.id,
                        nombre: val,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Botón de eliminar fila con ícono de basura
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red[700],
                  tooltip: widget.puedeEliminar
                      ? 'Eliminar componente'
                      : 'Mínimo 2 filas requeridas',
                  onPressed: widget.puedeEliminar
                      ? () => provider.eliminarComponente(widget.componente.id)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Campo numérico para la Nota (0 - 20)
                Expanded(
                  child: TextField(
                    controller: _notaController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Nota (0 - 20)',
                      hintText: '0 - 20',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final notaVal = double.tryParse(val) ?? 0.0;
                      // Validar rango 0 a 20
                      final notaClamped = notaVal.clamp(0.0, 20.0);
                      provider.actualizarComponente(
                        widget.componente.id,
                        nota: notaClamped,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Campo numérico para el Peso % (0 - 100)
                Expanded(
                  child: TextField(
                    controller: _pesoController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Peso (%)',
                      hintText: '0 - 100',
                      isDense: true,
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    onChanged: (val) {
                      final pesoVal = double.tryParse(val) ?? 0.0;
                      // Validar rango 0 a 100
                      final pesoClamped = pesoVal.clamp(0.0, 100.0);
                      provider.actualizarComponente(
                        widget.componente.id,
                        peso: pesoClamped,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
