import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/componentes_provider.dart';
import '../widgets/app_bar_nivel.dart';
import '../widgets/banner_sin_cuenta.dart';
import '../widgets/boton_punteado.dart';
import '../widgets/card_resultado.dart';
import '../widgets/cta_crear_cuenta.dart';
import '../widgets/fila_componente.dart';
import '../widgets/linea_pesos.dart';
import '../services/calculadora_promedio.dart';
import 'auth_screen.dart';
import 'ciclos_screen.dart';
import 'recordatorios_screen.dart';
import 'perfil_ajustes_screen.dart';
import '../widgets/dashboard_academico_widget.dart';

/// Pantalla principal: Dashboard académico (H27) y calculadora rápida
/// de promedio ponderado. Sirve tanto con cuenta como sin cuenta.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _vistaSeleccionada = 0; // 0: Dashboard Académico, 1: Calculadora Rápida

  Future<void> _confirmarReinicio(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Reiniciar la calculadora?'),
        content: const Text(
          'Se borrarán los componentes actuales y volverás a 2 filas vacías.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
    if (confirmar == true && context.mounted) {
      context.read<ComponentesProvider>().reiniciar();
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (e) {
      user = null;
    }
    // Una cuenta sin verificar se trata como modo sin cuenta.
    final esSinCuenta = user == null || !user.emailVerified;
    final String userName = user?.email?.split('@').first ?? '';

    final reiniciar = IconButton(
      icon: const Icon(Icons.restart_alt_rounded),
      tooltip: 'Reiniciar calculadora',
      onPressed: () => _confirmarReinicio(context),
    );

    return Scaffold(
      appBar: esSinCuenta
          ? AppBarNivel(
              padre: 'Modo sin cuenta',
              titulo: 'Calculadora rápida',
              acciones: [reiniciar],
            )
          : AppBarNivel(
              padre: userName.isNotEmpty ? 'Hola, $userName' : 'Tu cuenta',
              titulo: _vistaSeleccionada == 0
                  ? 'Dashboard Académico'
                  : 'Calculadora rápida',
              mostrarAtras: false,
              acciones: [
                // H10 - Acceso a gestion de ciclos
                IconButton(
                  icon: const Icon(Icons.school_rounded),
                  tooltip: 'Mis ciclos',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CiclosScreen()),
                    );
                  },
                ),
                // H26 - Acceso a recordatorios de evaluaciones
                IconButton(
                  icon: const Icon(Icons.event_note_rounded),
                  tooltip: 'Recordatorios',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RecordatoriosScreen(),
                      ),
                    );
                  },
                ),
                // H28 - Acceso a perfil y ajuste de tema
                IconButton(
                  icon: const Icon(Icons.person_outline_rounded),
                  tooltip: 'Perfil y Tema',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PerfilAjustesScreen(),
                      ),
                    );
                  },
                ),
                if (_vistaSeleccionada == 1) reiniciar,
              ],
            ),
      body: esSinCuenta
          ? _buildCalculadora(context, esSinCuenta: true)
          : Column(
              children: [
                // Selector segmentado de vista (H27)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment<int>(
                          value: 0,
                          icon: Icon(Icons.dashboard_rounded),
                          label: Text('Mi Resumen'),
                        ),
                        ButtonSegment<int>(
                          value: 1,
                          icon: Icon(Icons.calculate_rounded),
                          label: Text('Calculadora'),
                        ),
                      ],
                      selected: {_vistaSeleccionada},
                      onSelectionChanged: (Set<int> seleccion) {
                        setState(() {
                          _vistaSeleccionada = seleccion.first;
                        });
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: _vistaSeleccionada == 0
                      ? DashboardAcademicoWidget(uid: user.uid)
                      : _buildCalculadora(context, esSinCuenta: false),
                ),
              ],
            ),
      bottomNavigationBar: esSinCuenta
          ? Consumer<ComponentesProvider>(
              builder: (context, provider, child) => CtaCrearCuenta(
                cantidadComponentes: provider.componentes.length,
                onCrearCuenta: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AuthScreen(modoVincular: true),
                    ),
                  );
                },
              ),
            )
          : null,
    );
  }

  Widget _buildCalculadora(BuildContext context, {required bool esSinCuenta}) {
    return Consumer<ComponentesProvider>(
      builder: (context, provider, child) {
        final componentes = provider.componentes;
        final promedio = CalculadoraPromedio.calcularPromedio(componentes);

        // Si no hay promedio, se explica por que (sin tocar la logica de H02).
        String textoSinNota = 'Sin notas aún';
        String? subtituloSinNota;
        if (promedio == null) {
          if (!provider.esSumaPesosValida) {
            textoSinNota = 'Completa los pesos';
            subtituloSinNota = 'Deben sumar 100% para calcular';
          } else {
            textoSinNota = 'Revisa los datos';
            subtituloSinNota = 'Notas de 0 a 20 y pesos mayores a 0';
          }
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            if (esSinCuenta) ...[
              const BannerSinCuenta(),
              const SizedBox(height: 12),
            ],
            CardResultado(
              nota: promedio,
              titulo: 'Promedio final',
              subtitulo: promedio == null ? subtituloSinNota : null,
              textoSinNota: textoSinNota,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: LineaPesos(suma: provider.sumaPesos),
            ),
            const SizedBox(height: 16),
            const _EncabezadoTabla(),
            const SizedBox(height: 8),
            for (final item in componentes) ...[
              FilaComponente(
                key: ValueKey(item.id),
                componente: item,
                puedeEliminar: provider.puedeEliminar,
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            BotonPunteado(
              texto: 'Agregar componente',
              onPressed: provider.agregarComponente,
            ),
          ],
        );
      },
    );
  }
}

class _EncabezadoTabla extends StatelessWidget {
  const _EncabezadoTabla();

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return ExcludeSemantics(
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text('Componente', style: estilo),
            ),
          ),
          const SizedBox(width: ColumnasComponente.separacion),
          SizedBox(
            width: ColumnasComponente.nota,
            child: Text('Nota', textAlign: TextAlign.center, style: estilo),
          ),
          const SizedBox(width: ColumnasComponente.separacion),
          SizedBox(
            width: ColumnasComponente.peso,
            child: Text('Peso %', textAlign: TextAlign.center, style: estilo),
          ),
          const SizedBox(width: ColumnasComponente.borrar + 8),
        ],
      ),
    );
  }
}
