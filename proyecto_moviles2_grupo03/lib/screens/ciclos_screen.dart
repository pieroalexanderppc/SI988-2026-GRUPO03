import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/ciclo.dart';
import '../services/calculo_curso_service.dart';
import '../services/calculos_multinivel.dart';
import '../services/ciclos_service.dart';
import '../widgets/card_resultado.dart';
import '../widgets/dialogos.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/pondera_logo.dart';
import '../widgets/seccion_titulo.dart';
import '../widgets/tarjeta_ciclo.dart';
import 'cursos_screen.dart';

/// Pantalla 03 - Tus ciclos (H10), con su estado vacio (03b).
class CiclosScreen extends StatefulWidget {
  const CiclosScreen({super.key});

  @override
  State<CiclosScreen> createState() => _CiclosScreenState();
}

class _CiclosScreenState extends State<CiclosScreen> {
  final CiclosService _service = CiclosService();
  final CalculoCursoService _calculoService = CalculoCursoService();

  User? _user;
  Stream<List<Ciclo>>? _ciclosStream;

  /// Resumen por ciclo, cacheado para no recalcular en cada build.
  final Map<String, Future<ResumenCiclo>> _resumenes = {};

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    final uid = _user?.uid;
    if (uid != null) _ciclosStream = _service.obtenerCiclos(uid);
  }

  Future<ResumenCiclo> _resumenDe(String cicloId) =>
      _resumenes.putIfAbsent(cicloId, () => _calculoService.obtenerResumenCiclo(_user!.uid, cicloId));

  void _recalcular() => setState(_resumenes.clear);

  String get _nombreUsuario => _user?.email?.split('@').first ?? '';

  String get _iniciales {
    final partes = _nombreUsuario.split(RegExp(r'[._\-\s]+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, partes.first.length.clamp(1, 2)).toUpperCase();
    return (partes[0][0] + partes[1][0]).toUpperCase();
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _crearCiclo() async {
    final uid = _user?.uid;
    if (uid == null) return;
    final nombre = await pedirNombre(
      context,
      titulo: 'Nuevo ciclo',
      etiqueta: 'Nombre del ciclo',
      hint: 'Ej. 2026-II',
      textoBoton: 'Crear',
    );
    if (nombre == null) return;
    try {
      await _service.crearCiclo(uid, nombre);
      if (mounted) _mostrarMensaje('Ciclo creado.');
    } catch (_) {
      if (mounted) _mostrarMensaje('No se pudo crear el ciclo.');
    }
  }

  Future<void> _eliminarCiclo(Ciclo ciclo) async {
    final uid = _user?.uid;
    if (uid == null) return;
    final ok = await confirmarEliminar(
      context,
      titulo: 'Eliminar ciclo',
      mensaje: 'Se eliminará "${ciclo.nombre}" con todos sus cursos, unidades y notas.',
    );
    if (!ok) return;
    try {
      await _service.eliminarCiclo(uid, ciclo.id);
      if (mounted) _mostrarMensaje('Ciclo eliminado.');
    } catch (_) {
      if (mounted) _mostrarMensaje('No se pudo eliminar el ciclo.');
    }
  }

  Future<void> _abrirCiclo(Ciclo ciclo) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CursosScreen(cicloId: ciclo.id, cicloNombre: ciclo.nombre)),
    );
    _recalcular();
  }

  @override
  Widget build(BuildContext context) {
    final stream = _ciclosStream;
    if (stream == null) {
      return const Scaffold(body: Center(child: Text('Debes iniciar sesión para gestionar tus ciclos.')));
    }
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 0,
        title: Row(
          children: [
            const PonderaLogo(size: 32),
            const SizedBox(width: 10),
            Text('Pondera', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22)),
          ],
        ),
        actions: [
          Semantics(
            label: 'Cuenta de $_nombreUsuario',
            child: CircleAvatar(
              radius: 18,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                _iniciales,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<List<Ciclo>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('No se pudieron cargar los ciclos.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final ciclos = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              _recalcular();
              await Future.wait(ciclos.map((c) => _resumenDe(c.id)));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 104),
              children: [
                if (_nombreUsuario.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'Hola, $_nombreUsuario',
                      style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text('Tus ciclos', style: Theme.of(context).textTheme.headlineMedium),
                ),
                const SizedBox(height: 18),
                if (ciclos.isEmpty)
                  EstadoVacio(
                    icono: Icons.school_rounded,
                    titulo: 'Aún no tienes ciclos',
                    texto: 'Crea tu ciclo actual y empieza a registrar tus cursos y notas. '
                        'Pondera calcula el resto.',
                    textoBoton: 'Crear mi primer ciclo',
                    onPressed: _crearCiclo,
                    tip: 'Puedes registrar desde el ciclo 1 hasta el 10.',
                  )
                else ...[
                  _PromedioAcumulado(resumenes: [for (final c in ciclos) _resumenDe(c.id)]),
                  const SizedBox(height: 22),
                  SeccionTitulo(
                    'Ciclos',
                    trailing: Text(
                      'Más reciente primero',
                      style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < ciclos.length; i++) ...[
                    FutureBuilder<ResumenCiclo>(
                      key: ValueKey(ciclos[i].id),
                      future: _resumenDe(ciclos[i].id),
                      builder: (context, resumen) {
                        final r = resumen.data;
                        final cursos = r == null
                            ? 'Cargando cursos…'
                            : (r.cantidadCursos == 1 ? '1 curso' : '${r.cantidadCursos} cursos');
                        return TarjetaCiclo(
                          numero: ciclos.length - i,
                          nombre: ciclos[i].nombre,
                          subtitulo: cursos,
                          promedio: r?.promedio,
                          destacado: i == 0,
                          cargando: resumen.connectionState != ConnectionState.done,
                          onTap: () => _abrirCiclo(ciclos[i]),
                          onLongPress: () => mostrarOpciones(
                            context,
                            titulo: ciclos[i].nombre,
                            opciones: [
                              OpcionMenu(
                                icono: Icons.delete_outline_rounded,
                                texto: 'Eliminar ciclo',
                                onTap: () => _eliminarCiclo(ciclos[i]),
                                destructiva: true,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearCiclo,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo ciclo'),
      ),
    );
  }
}

/// Promedio acumulado: promedio simple de los ciclos que tienen notas.
class _PromedioAcumulado extends StatelessWidget {
  final List<Future<ResumenCiclo>> resumenes;

  const _PromedioAcumulado({required this.resumenes});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ResumenCiclo>>(
      future: Future.wait(resumenes),
      builder: (context, snapshot) {
        final datos = snapshot.data;
        if (datos == null) {
          return const CardResultado(nota: null, titulo: 'Promedio acumulado', subtitulo: 'Calculando…');
        }
        final promedios = datos.map((r) => r.promedio).whereType<double>().toList();
        final promedio = promedios.isEmpty
            ? null
            : CalculosMultinivel.redondearUnDecimal(promedios.reduce((a, b) => a + b) / promedios.length);
        final registrados = datos.length == 1 ? '1 ciclo registrado' : '${datos.length} ciclos registrados';
        return CardResultado(
          nota: promedio,
          titulo: 'Promedio acumulado',
          subtitulo: registrados,
        );
      },
    );
  }
}
