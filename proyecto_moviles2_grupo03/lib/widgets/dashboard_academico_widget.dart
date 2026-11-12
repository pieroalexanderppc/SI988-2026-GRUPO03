import 'package:flutter/material.dart';

import '../models/ciclo.dart';
import '../models/curso.dart';
import '../models/recordatorio_evaluacion.dart';
import '../services/ciclos_service.dart';
import '../services/cursos_service.dart';
import '../services/recordatorios_service.dart';
import '../screens/ciclos_screen.dart';
import '../screens/recordatorios_screen.dart';
import '../screens/unidades_screen.dart';
import '../widgets/dialogos.dart';

/// Widget de Dashboard Académico para la pantalla principal (H27).
///
/// Muestra un resumen del ciclo activo, métricas de créditos y cursos,
/// alertas de evaluaciones próximas (H26) y semáforo visual de estado por curso.
class DashboardAcademicoWidget extends StatelessWidget {
  final String uid;

  const DashboardAcademicoWidget({
    super.key,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ciclosService = CiclosService();

    return StreamBuilder<List<Ciclo>>(
      stream: ciclosService.obtenerCiclos(uid),
      builder: (context, snapshotCiclos) {
        if (snapshotCiclos.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final ciclos = snapshotCiclos.data ?? [];

        if (ciclos.isEmpty) {
          return _buildEstadoSinCiclos(context, theme, ciclosService);
        }

        final cicloActivo = ciclos.first;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // 1. Tarjeta Resumen del Ciclo Activo
            _buildTarjetaCicloActivo(context, theme, cicloActivo),
            const SizedBox(height: 16),

            // 2. Banner de Próximas Evaluaciones (H26)
            _buildProximasEvaluaciones(context, theme),
            const SizedBox(height: 20),

            // 3. Encabezado Cursos con Semáforo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CURSOS DEL CICLO',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _agregarCurso(context, cicloActivo.id),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuevo curso'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 4. Lista de Cursos del Ciclo
            _buildListaCursos(context, theme, cicloActivo.id),
          ],
        );
      },
    );
  }

  Widget _buildEstadoSinCiclos(
    BuildContext context,
    ThemeData theme,
    CiclosService service,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.school_rounded,
                size: 56,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '¡Comienza tu gestión académica!',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primer ciclo universitario (ej. 2026-I) para registrar tus cursos, ver tus promedios y simular notas.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _crearCiclo(context, service),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear mi primer ciclo'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _crearCiclo(BuildContext context, CiclosService service) async {
    final nombre = await pedirNombre(
      context,
      titulo: 'Nuevo ciclo',
      etiqueta: 'Nombre del ciclo',
      hint: 'ej. 2026-I, Ciclo VII',
      textoBoton: 'Crear ciclo',
    );
    if (nombre != null && nombre.trim().isNotEmpty) {
      await service.crearCiclo(uid, nombre.trim());
    }
  }

  Future<void> _agregarCurso(BuildContext context, String cicloId) async {
    final resultado = await pedirNombreYCreditos(
      context,
      titulo: 'Nuevo curso',
      etiquetaNombre: 'Nombre del curso',
      hintNombre: 'ej. Soluciones Móviles II',
      textoBoton: 'Crear curso',
    );
    if (resultado != null && resultado.nombre.trim().isNotEmpty) {
      await CursosService().crearCurso(
        uid,
        cicloId,
        resultado.nombre.trim(),
        creditos: resultado.creditos,
      );
    }
  }

  Widget _buildTarjetaCicloActivo(
    BuildContext context,
    ThemeData theme,
    Ciclo ciclo,
  ) {
    final cursosService = CursosService();

    return StreamBuilder<List<Curso>>(
      stream: cursosService.obtenerCursos(uid, ciclo.id),
      builder: (context, snapshot) {
        final cursos = snapshot.data ?? [];
        final totalCreditos = cursos.fold<int>(
          0,
          (acum, c) => acum + c.creditosEfectivos,
        );

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          color: theme.colorScheme.surfaceContainerLowest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Ciclo Activo',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new_rounded, size: 20),
                      tooltip: 'Ver todos los ciclos',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CiclosScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ciclo.nombre,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildKpi(
                      theme,
                      Icons.book_rounded,
                      '${cursos.length}',
                      'Cursos',
                    ),
                    const SizedBox(width: 24),
                    _buildKpi(
                      theme,
                      Icons.stars_rounded,
                      '$totalCreditos',
                      'Créditos',
                    ),
                    const SizedBox(width: 24),
                    _buildKpi(
                      theme,
                      Icons.rule_rounded,
                      '10.5',
                      'Mín. Aprob.',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKpi(ThemeData theme, IconData icono, String valor, String label) {
    return Row(
      children: [
        Icon(icono, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valor,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProximasEvaluaciones(BuildContext context, ThemeData theme) {
    final recordatoriosService = RecordatoriosService();

    return StreamBuilder<List<RecordatorioEvaluacion>>(
      stream: recordatoriosService.obtenerRecordatorios(uid),
      builder: (context, snapshot) {
        final todos = snapshot.data ?? [];
        final pendientes = todos.where((r) => !r.completado).toList();

        if (pendientes.isEmpty) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
            child: ListTile(
              leading: Icon(
                Icons.check_circle_outline_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Sin evaluaciones pendientes'),
              subtitle: const Text(
                'Organiza tus fechas de exámenes en Recordatorios.',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.add_alert_rounded),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RecordatoriosScreen(),
                    ),
                  );
                },
              ),
            ),
          );
        }

        // Ordenamos por fecha más próxima
        pendientes.sort((a, b) => a.fecha.compareTo(b.fecha));
        final proxima = pendientes.first;

        final esUrgente = proxima.esHoy || proxima.esManana || proxima.estaVencido;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: esUrgente
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary.withValues(alpha: 0.5),
              width: esUrgente ? 1.5 : 1.0,
            ),
          ),
          color: theme.colorScheme.surfaceContainerLowest,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_active_rounded,
                          size: 18,
                          color: esUrgente
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'PRÓXIMA EVALUACIÓN',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: esUrgente
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: esUrgente
                            ? theme.colorScheme.error.withValues(alpha: 0.12)
                            : theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        proxima.tiempoRestanteTexto,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: esUrgente
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  proxima.titulo,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${proxima.cursoNombre} · ${proxima.fechaFormateada}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RecordatoriosScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Ver todas (${pendientes.length}) >',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListaCursos(
    BuildContext context,
    ThemeData theme,
    String cicloId,
  ) {
    final cursosService = CursosService();

    return StreamBuilder<List<Curso>>(
      stream: cursosService.obtenerCursos(uid, cicloId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final cursos = snapshot.data ?? [];

        if (cursos.isEmpty) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 40,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  const Text('No hay cursos registrados en este ciclo'),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: () => _agregarCurso(context, cicloId),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar curso'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: cursos.map((curso) {
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              color: theme.colorScheme.surfaceContainerLowest,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.school_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                title: Text(
                  curso.nombre,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${curso.creditosEfectivos} créditos · Semáforo activo',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: Colors.green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Al día',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UnidadesScreen(
                        cursoId: curso.id,
                        cursoNombre: curso.nombre,
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
