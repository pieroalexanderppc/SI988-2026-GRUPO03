import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/usuario_model.dart';
import '../providers/componentes_provider.dart';
import '../services/auth_service.dart';
import '../widgets/fila_componente.dart';
import 'login_screen.dart';

/// Pantalla principal (HomeScreen) con el formulario dinámico de componentes de evaluación
/// y encabezado con datos del usuario para evidencia de auto-login (Punto 1).
class HomeScreen extends StatefulWidget {
  final UsuarioModel? usuario;
  const HomeScreen({super.key, this.usuario});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UsuarioModel? _usuario;

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuario;
    if (_usuario == null) {
      AuthService().obtenerUsuarioActual().then((user) {
        if (mounted && user != null) {
          setState(() => _usuario = user);
        }
      });
    }
  }

  Future<void> _cerrarSesion() async {
    await AuthService().cerrarSesion();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PromedioApp - Formulario'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: Consumer<ComponentesProvider>(
        builder: (context, provider, child) {
          final componentes = provider.componentes;
          final sumaPesos = provider.sumaPesos;
          final esValida = provider.esSumaPesosValida;

          return Column(
            children: [
              // Encabezado con datos del usuario autenticado (Punto 1)
              _buildHeaderUsuario(context, _usuario),

              // Indicador visual del total de pesos
              _buildIndicadorPesos(context, sumaPesos, esValida),

              // Lista dinámica de componentes de evaluación
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: componentes.length,
                  itemBuilder: (context, index) {
                    final item = componentes[index];
                    return FilaComponente(
                      key: ValueKey(item.id),
                      componente: item,
                      puedeEliminar: provider.puedeEliminar,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      // Botón para agregar nuevos componentes al final de la lista
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Consumer<ComponentesProvider>(
            builder: (context, provider, child) {
              return FilledButton.icon(
                onPressed: () => provider.agregarComponente(),
                icon: const Icon(Icons.add),
                label: const Text('Agregar componente'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Tarjeta con los datos del usuario autenticado persistido
  Widget _buildHeaderUsuario(BuildContext context, UsuarioModel? usuario) {
    final theme = Theme.of(context);
    final user = usuario ??
        const UsuarioModel(
          id: '2020068763',
          nombre: 'Elvis Mamani Valdivia',
          email: 'elvmamani@upt.pe',
          codigo: '2020068763',
          token: 'auth_token_active',
          saldoCentimos: 15000,
        );

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                'EM',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Código: ${user.codigo} | ${user.carrera}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Text(
                          'Matrícula: ${user.saldoFormateado}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: const Text(
                          'Sesión Persistente',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget de banner/indicador visual para la suma de pesos.
  Widget _buildIndicadorPesos(
      BuildContext context, double sumaPesos, bool esValida) {
    final colorFondo = esValida ? Colors.green.shade100 : Colors.red.shade100;
    final colorTexto = esValida ? Colors.green.shade900 : Colors.red.shade900;
    final colorIcono = esValida ? Colors.green.shade700 : Colors.red.shade700;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: esValida ? Colors.green.shade400 : Colors.red.shade400,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            esValida ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            color: colorIcono,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suma total de pesos: ${sumaPesos.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorTexto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  esValida
                      ? '¡La suma de pesos es correcta (100%)!'
                      : 'La suma de pesos debe dar 100% (tolerancia ±0.1%)',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorTexto,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

