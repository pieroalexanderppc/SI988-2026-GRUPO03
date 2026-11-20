import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/curso.dart';
import '../services/calculadora_simulacion_ciclo_service.dart';
import '../services/calculos_multinivel.dart';
import '../theme/estado_nota_colors.dart';
import '../widgets/app_bar_nivel.dart';
import '../widgets/estado_vacio.dart';

/// Pantalla interactiva del Simulador Multiescenario de Cierre de Ciclo ("¿Qué pasa si...?") (H36).
class SimuladorCicloScreen extends StatefulWidget {
  final String cicloId;
  final String cicloNombre;
  final List<Curso> cursos;
  final Map<String, ResultadoCalculoCurso> resultados;
  final double? ppaHistorico;
  final int creditosHistoricos;

  const SimuladorCicloScreen({
    super.key,
    required this.cicloId,
    required this.cicloNombre,
    required this.cursos,
    required this.resultados,
    this.ppaHistorico,
    this.creditosHistoricos = 0,
  });

  @override
  State<SimuladorCicloScreen> createState() => _SimuladorCicloScreenState();
}

class _SimuladorCicloScreenState extends State<SimuladorCicloScreen> {
  late List<ItemSimulacionCurso> _items;
  PresetSimulacion? _presetSeleccionado;

  @override
  void initState() {
    super.initState();
    _reiniciarSimulacion();
  }

  void _reiniciarSimulacion() {
    setState(() {
      _items = CalculadoraSimulacionCicloService.inicializarDesdeCursos(
        cursos: widget.cursos,
        resultados: widget.resultados,
      );
      _presetSeleccionado = null;
    });
  }

  void _aplicarPreset(PresetSimulacion preset) {
    HapticFeedback.mediumImpact();
    setState(() {
      _items = CalculadoraSimulacionCicloService.aplicarPreset(
        items: _items,
        preset: preset,
      );
      _presetSeleccionado = preset;
    });
  }

  void _actualizarNotaCurso(int index, double nuevaNota) {
    HapticFeedback.selectionClick();
    setState(() {
      _items[index] = _items[index].copiarCon(notaSimulada: nuevaNota);
      _presetSeleccionado = null; // Cambio manual desactiva preset
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cursos.isEmpty) {
      return Scaffold(
        appBar: AppBarNivel(
          padre: widget.cicloNombre,
          titulo: 'Simulador de cierre de ciclo',
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: EstadoVacio(
            icono: Icons.auto_graph_rounded,
            titulo: 'Sin cursos para simular',
            texto:
                'Agrega cursos y notas en este ciclo para proyectar escenarios de cierre.',
            textoBoton: 'Volver',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }

    final resultado = CalculadoraSimulacionCicloService.calcularSimulacion(
      items: _items,
      ppaHistorico: widget.ppaHistorico,
      creditosHistoricos: widget.creditosHistoricos,
    );

    final colors = Theme.of(context).extension<EstadoNotaColors>() ??
        EstadoNotaColors.light;

    return Scaffold(
      appBar: AppBarNivel(
        padre: widget.cicloNombre,
        titulo: 'Simulador multiescenario',
        acciones: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Reiniciar valores',
            onPressed: _reiniciarSimulacion,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Tarjeta Resumen de Métricas Proyectadas
          _buildPanelMetricas(context, resultado, colors),

          const SizedBox(height: 16),

          // 2. Barra de Presets Rápidos
          _buildBarraPresets(context),

          const SizedBox(height: 16),

          // 3. Título de Asignaturas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ajustar notas proyectadas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '${_items.length} cursos',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 4. Sliders interactivos por curso
          ..._items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildTarjetaCursoSlider(context, index, item, colors);
          }),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPanelMetricas(
    BuildContext context,
    ResultadoSimulacionCiclo res,
    EstadoNotaColors colors,
  ) {
    final colorPromedio = res.promedioSimulado >= 15.0
        ? const Color(0xFF3B36C4)
        : (res.promedioSimulado >= 10.5
            ? colors.aprobado
            : colors.desaprobado);

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Promedio Simulado
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROMEDIO DEL CICLO (SIMULADO)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            res.promedioSimulado.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: colorPromedio,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: colorPromedio.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              res.cicloAprobado
                                  ? (res.promedioSimulado >= 15.0
                                      ? 'Distinción'
                                      : 'Aprobado')
                                  : 'En riesgo',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorPromedio,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Badge Tercio Superior
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: res.esTercioSuperior
                        ? const Color(0xFF3B36C4).withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: res.esTercioSuperior
                          ? const Color(0xFF3B36C4)
                          : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        res.esTercioSuperior
                            ? Icons.military_tech_rounded
                            : Icons.track_changes_rounded,
                        color: res.esTercioSuperior
                            ? const Color(0xFF3B36C4)
                            : Colors.grey.shade700,
                        size: 26,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        res.esTercioSuperior
                            ? 'Tercio Superior'
                            : 'Meta: 15.0',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: res.esTercioSuperior
                              ? const Color(0xFF3B36C4)
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Métricas secundarias (Créditos y PPA Proyectado)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricaItem(
                  context,
                  titulo: 'Créditos Aprobados',
                  valor: '${res.creditosAprobados} / ${res.totalCreditos}',
                  color: res.creditosDesaprobados == 0
                      ? colors.aprobado
                      : colors.desaprobado,
                ),
                if (res.ppaProyectado != null)
                  _buildMetricaItem(
                    context,
                    titulo: 'PPA Histórico Proyectado',
                    valor: res.ppaProyectado!.toStringAsFixed(1),
                    subtitulo: res.impactoPpa != null
                        ? '${res.impactoPpa! >= 0 ? "+" : ""}${res.impactoPpa!.toStringAsFixed(1)} pts'
                        : null,
                    color: const Color(0xFF3B36C4),
                  ),
                _buildMetricaItem(
                  context,
                  titulo: 'Distancia Tercio Sup.',
                  valor: res.esTercioSuperior
                      ? 'Alcanzado'
                      : '-${res.distanciaTercioSuperior.toStringAsFixed(1)} pts',
                  color: res.esTercioSuperior
                      ? const Color(0xFF157A45)
                      : Colors.orange.shade800,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricaItem(
    BuildContext context, {
    required String titulo,
    required String valor,
    String? subtitulo,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (subtitulo != null)
          Text(
            subtitulo,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
      ],
    );
  }

  Widget _buildBarraPresets(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: const Icon(Icons.check_circle_outline_rounded, size: 16),
              label: const Text('Mínimo Aprobatorio (10.5)'),
              backgroundColor:
                  _presetSeleccionado == PresetSimulacion.minimoAprobatorio
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
              onPressed: () =>
                  _aplicarPreset(PresetSimulacion.minimoAprobatorio),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: const Icon(Icons.analytics_outlined, size: 16),
              label: const Text('Escenario Realista'),
              backgroundColor:
                  _presetSeleccionado == PresetSimulacion.realista
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
              onPressed: () => _aplicarPreset(PresetSimulacion.realista),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: const Icon(Icons.star_outline_rounded, size: 16),
              label: const Text('Meta Distinción (16.0)'),
              backgroundColor:
                  _presetSeleccionado == PresetSimulacion.metaDistincion
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
              onPressed: () => _aplicarPreset(PresetSimulacion.metaDistincion),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaCursoSlider(
    BuildContext context,
    int index,
    ItemSimulacionCurso item,
    EstadoNotaColors colors,
  ) {
    final colorNota =
        item.esAprobado ? colors.aprobado : colors.desaprobado;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.cursoNombre,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.creditosEfectivos} créditos'
                        '${item.notaActual != null ? " · Actual: ${item.notaActual!.toStringAsFixed(1)}" : ""}',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorNota.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorNota.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    item.notaSimulada.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorNota,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Disminuir 0.5',
                  onPressed: item.notaSimulada > 0.0
                      ? () => _actualizarNotaCurso(
                            index,
                            (item.notaSimulada - 0.5).clamp(0.0, 20.0),
                          )
                      : null,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: colorNota,
                      thumbColor: colorNota,
                      overlayColor: colorNota.withValues(alpha: 0.15),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: item.notaSimulada,
                      min: 0.0,
                      max: 20.0,
                      divisions: 40, // De 0.5 en 0.5
                      label: item.notaSimulada.toStringAsFixed(1),
                      onChanged: (val) => _actualizarNotaCurso(index, val),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Aumentar 0.5',
                  onPressed: item.notaSimulada < 20.0
                      ? () => _actualizarNotaCurso(
                            index,
                            (item.notaSimulada + 0.5).clamp(0.0, 20.0),
                          )
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
