import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/curso.dart';
import '../services/calculo_curso_service.dart';
import '../services/calculos_multinivel.dart';
import '../services/ciclos_service.dart';
import '../services/cursos_service.dart';
import '../theme/estado_nota_colors.dart';
import '../widgets/app_bar_nivel.dart';
import '../widgets/card_resultado.dart';
import '../widgets/dialogos.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/seccion_titulo.dart';
import '../widgets/tarjeta_curso.dart';
import 'escanear_notas_screen.dart';
import 'simulador_screen.dart';
import 'unidades_screen.dart';

class CursosScreen extends StatefulWidget {
  final String cicloId;
  final String cicloNombre;

  const CursosScreen({
    super.key,
    required this.cicloId,
    required this.cicloNombre,
  });

  @override
  State<CursosScreen> createState() => _CursosScreenState();
}

class _CursosScreenState extends State<CursosScreen> {
  final CursosService _service = CursosService();
  final CiclosService _ciclosService = CiclosService();
  final CalculoCursoService _calculoService = CalculoCursoService();

  String? _uid;
  Stream<List<Curso>>? _cursosStream;

  String _claveCalculos = '';
  Future<Map<String, ResultadoCalculoCurso>>? _calculos;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    final uid = _uid;

    if (uid != null) {
      _cursosStream = _service.obtenerCursos(uid, widget.cicloId);
    }
  }

  Future<Map<String, ResultadoCalculoCurso>> _calculosPara(
    List<Curso> cursos,
  ) {
    final clave = cursos.map((c) => c.id).join(',');

    if (_calculos == null || clave != _claveCalculos) {
      _claveCalculos = clave;
      _calculos = _calculoService.obtenerCalculosCursos(_uid!, cursos);
    }

    return _calculos!;
  }

  void _recalcular() {
    setState(() {
      _calculos = null;
    });
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _crearOEditarCurso({Curso? curso}) async {
    final uid = _uid;
    if (uid == null) return;

    final nombre = await pedirNombre(
      context,
      titulo: curso == null ? 'Agregar curso' : 'Editar curso',
      etiqueta: 'Nombre del curso',
      hint: 'Ej. Soluciones Móviles II',
      inicial: curso?.nombre ?? '',
      textoBoton: curso == null ? 'Agregar' : 'Guardar',
    );

    if (nombre == null) return;

    try {
      if (curso == null) {
        await _service.crearCurso(uid, widget.cicloId, nombre);
      } else {
        await _service.actualizarCurso(uid, curso, nombre);
      }

      if (mounted) {
        _mostrarMensaje(
          curso == null ? 'Curso agregado.' : 'Curso actualizado.',
        );
      }
    } catch (_) {
      if (mounted) _mostrarMensaje('No se pudo guardar el curso.');
    }
  }

  Future<void> _eliminarCurso(Curso curso) async {
    final uid = _uid;
    if (uid == null) return;

    final ok = await confirmarEliminar(
      context,
      titulo: 'Eliminar curso',
      mensaje:
          'Se eliminará "${curso.nombre}" con todas sus unidades y notas.',
    );

    if (!ok) return;

    try {
      await _service.eliminarCurso(uid, curso.id);
      if (mounted) _mostrarMensaje('Curso eliminado.');
    } catch (_) {
      if (mounted) _mostrarMensaje('No se pudo eliminar el curso.');
    }
  }

  Future<void> _eliminarCiclo() async {
    final uid = _uid;
    if (uid == null) return;

    final ok = await confirmarEliminar(
      context,
      titulo: 'Eliminar ciclo',
      mensaje:
          'Se eliminará "${widget.cicloNombre}" con todos sus cursos, unidades y notas.',
    );

    if (!ok) return;

    try {
      await _ciclosService.eliminarCiclo(uid, widget.cicloId);

      if (!mounted) return;

      _mostrarMensaje('Ciclo eliminado.');
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) _mostrarMensaje('No se pudo eliminar el ciclo.');
    }
  }

  Future<void> _escanearReporte() async {
    final cursoId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => EscanearNotasScreen(
          cicloId: widget.cicloId,
          cicloNombre: widget.cicloNombre,
        ),
      ),
    );

    if (cursoId != null) _recalcular();
  }

  Future<void> _abrirCurso(Curso curso) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UnidadesScreen(
          cursoId: curso.id,
          cursoNombre: curso.nombre,
        ),
      ),
    );

    if (mounted) _recalcular();
  }

  // H16 + H17: simulador de nota para el curso completo con UI responsiva.
  Future<void> _abrirSimuladorCurso(Curso curso) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final pesos = await _calculoService.obtenerPesosUnidades(uid, curso.id);

      if (!mounted) return;

      if (pesos.isEmpty) {
        _mostrarMensaje('Este curso todavía no tiene unidades registradas.');
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SimuladorScreen(
            cursoId: curso.id,
            cursoNombre: curso.nombre,
            cicloNombre: widget.cicloNombre,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        _mostrarMensaje('No se pudo abrir el simulador del curso.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = _cursosStream;

    if (stream == null) {
      return const Scaffold(
        body: Center(child: Text('Debes iniciar sesión.')),
      );
    }

    return Scaffold(
      appBar: AppBarNivel(
        padre: 'Ciclo',
        titulo: widget.cicloNombre,
        acciones: [
          IconButton(
            icon: const Icon(Icons.document_scanner_rounded),
            tooltip: 'Escanear reporte de notas',
            onPressed: _escanearReporte,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Más opciones',
            onPressed: () => mostrarOpciones(
              context,
              titulo: widget.cicloNombre,
              opciones: [
                OpcionMenu(
                  icono: Icons.delete_outline_rounded,
                  texto: 'Eliminar ciclo',
                  onTap: _eliminarCiclo,
                  destructiva: true,
                ),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Curso>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('No se pudieron cargar los cursos.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final cursos = snapshot.data!;

          if (cursos.isEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                EstadoVacio(
                  icono: Icons.menu_book_rounded,
                  titulo: 'Aún no tienes cursos',
                  texto:
                      'Agrega los cursos que llevas en ${widget.cicloNombre}. '
                      'Luego registra sus unidades y notas.',
                  textoBoton: 'Agregar primer curso',
                  onPressed: _crearOEditarCurso,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _escanearReporte,
                    icon: const Icon(Icons.document_scanner_rounded),
                    label: const Text('Escanear reporte de notas'),
                  ),
                ),
              ],
            );
          }

          return FutureBuilder<Map<String, ResultadoCalculoCurso>>(
            future: _calculosPara(cursos),
            builder: (context, calc) {
              final resultados = calc.data ?? const {};
              final cargando =
                  calc.connectionState != ConnectionState.done;

              return RefreshIndicator(
                onRefresh: () async {
                  _recalcular();
                  await _calculosPara(cursos);
                },
                child: _lista(context, cursos, resultados, cargando),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearOEditarCurso,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar curso'),
      ),
    );
  }

  Widget _lista(
    BuildContext context,
    List<Curso> cursos,
    Map<String, ResultadoCalculoCurso> resultados,
    bool cargando,
  ) {
    final estado = EstadoNotaColors.of(context);
    final promedio =
        CalculoCursoService.promedioDeCursos(resultados.values);
    final conNotas =
        resultados.values.where((r) => r.notaActual != null).length;
    final enRiesgo =
        resultados.values.where((r) => (r.notaActual ?? 99) < 10.5).length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 104),
      children: [
        CardResultado(
          nota: cargando ? null : promedio,
          titulo: 'Promedio del ciclo',
          subtitulo: cargando
              ? 'Calculando…'
              : '$conNotas de ${cursos.length} cursos con notas',
        ),
        const SizedBox(height: 22),
        SeccionTitulo(
          'Cursos · ${cursos.length}',
          trailing: enRiesgo == 0
              ? null
              : Text(
                  enRiesgo == 1 ? '1 en riesgo' : '$enRiesgo en riesgo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: estado.desaprobado,
                  ),
                ),
        ),
        const SizedBox(height: 10),
        for (final curso in cursos) ...[
          TarjetaCurso(
            key: ValueKey(curso.id),
            nombre: curso.nombre,
            nota: resultados[curso.id]?.notaActual,
            pctEvaluado:
                resultados[curso.id]?.porcentajeEvaluado ?? 0,
            cargando: cargando,
            onTap: () => _abrirCurso(curso),
            onLongPress: () => mostrarOpciones(
              context,
              titulo: curso.nombre,
              opciones: [
                OpcionMenu(
                  icono: Icons.edit_rounded,
                  texto: 'Editar curso',
                  onTap: () => _crearOEditarCurso(curso: curso),
                ),
                OpcionMenu(
                  icono: Icons.delete_outline_rounded,
                  texto: 'Eliminar curso',
                  onTap: () => _eliminarCurso(curso),
                  destructiva: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: cargando
                  ? null
                  : () => _abrirSimuladorCurso(curso),
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Simulador de curso H16'),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}