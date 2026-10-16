import 'package:flutter/material.dart';
import '../theme/estado_nota_colors.dart';

/// Estado de una nota con icono + texto (DESIGN.md seccion 6).
/// Nunca comunica el estado solo con color.
class ChipEstado extends StatelessWidget {
  final double? nota;
  final double umbral;

  const ChipEstado({super.key, required this.nota, this.umbral = 10.5});

  @override
  Widget build(BuildContext context) {
    final estado = EstadoNotaColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final valor = nota;

    final IconData icono;
    final String texto;
    final Color color;
    if (valor == null) {
      icono = Icons.hourglass_empty_rounded;
      texto = 'Sin notas';
      color = scheme.onSurfaceVariant;
    } else if (valor >= umbral) {
      icono = Icons.check_circle_rounded;
      texto = 'Aprobado';
      color = estado.aprobado;
    } else {
      icono = Icons.cancel_rounded;
      texto = 'Desaprobado';
      color = estado.desaprobado;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 16, color: color),
        const SizedBox(width: 4),
        Text(texto, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
