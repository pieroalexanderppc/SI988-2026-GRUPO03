import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/estado_nota_colors.dart';
import '../utils/formato_nota.dart';
import 'borde_punteado.dart';
import 'chip_estado.dart';

/// Tarjeta de un curso dentro del ciclo (DESIGN.md seccion 6, pantalla 04).
/// Muestra la nota actual y cuanto del curso ya esta evaluado.
class TarjetaCurso extends StatelessWidget {
  final String nombre;
  final double? nota;

  /// Porcentaje del curso evaluado (0-100).
  final double pctEvaluado;
  final bool cargando;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const TarjetaCurso({
    super.key,
    required this.nombre,
    required this.nota,
    required this.pctEvaluado,
    required this.onTap,
    this.cargando = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final estado = EstadoNotaColors.of(context);
    final valor = nota;
    final enRiesgo = valor != null && valor < 10.5;
    final sinNotas = !cargando && valor == null;

    final evaluado = FormatoNota.porcentaje(pctEvaluado.clamp(0, 100).toDouble());

    Widget tarjeta = Card(
      color: enRiesgo ? estado.desaprobadoFondo.withValues(alpha: 0.45) : null,
      shape: enRiesgo
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: estado.pistaDesaprobado),
            )
          : sinNotas
              ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
              : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: SizedBox(
                            width: 64,
                            height: 5,
                            child: LinearProgressIndicator(
                              value: (pctEvaluado / 100).clamp(0.0, 1.0),
                              backgroundColor: scheme.surfaceContainerHigh,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            sinNotas ? 'Sin notas todavía' : '$evaluado% evaluado',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (cargando)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: scheme.outline),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      FormatoNota.nota(valor),
                      style: AppTheme.estiloNota(
                        28,
                        color: estado.colorDeNota(valor, scheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ChipEstado(nota: valor),
                  ],
                ),
            ],
          ),
        ),
      ),
    );

    if (sinNotas) {
      tarjeta = BordePunteado(color: scheme.outline, radio: 20, grosor: 1.2, child: tarjeta);
    }

    return Semantics(
      button: true,
      label: '$nombre, ${valor == null ? 'sin notas' : 'nota ${FormatoNota.nota(valor)}, '
          '${enRiesgo ? 'desaprobado' : 'aprobado'}, $evaluado por ciento evaluado'}',
      excludeSemantics: true,
      child: tarjeta,
    );
  }
}
