import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/componentes_provider.dart';
import '../widgets/fila_componente.dart';
import '../services/calculadora_promedio.dart';
import 'welcome_screen.dart';
import 'auth_screen.dart';

/// Pantalla principal (HomeScreen) con el formulario dinámico de componentes de evaluación.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (e) {
      user = null;
    }
    final esSinCuenta = user == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PromedioApp - Formulario'),
        centerTitle: true,
        actions: [
          if (!esSinCuenta)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          if (esSinCuenta)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Volver',
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: Consumer<ComponentesProvider>(
        builder: (context, provider, child) {
          final componentes = provider.componentes;
          final sumaPesos = provider.sumaPesos;
          final esValida = provider.esSumaPesosValida;
          final promedio = CalculadoraPromedio.calcularPromedio(componentes);
          final String userName = user?.email?.split('@').first ?? '';

          return Column(
            children: [
              // Saludo personalizado (Fase 2)
              if (!esSinCuenta && userName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Hola, $userName 👋',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
              // Banner de modo sin cuenta
              if (esSinCuenta) _buildBannerSinCuenta(context),

              // Indicador visual del total de pesos
              _buildIndicadorPesos(context, sumaPesos, esValida),

              // Tarjeta de resultado del promedio
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: promedio != null
                    ? _buildTarjetaResultado(context, promedio)
                    : const SizedBox.shrink(key: ValueKey('empty_promedio')),
              ),

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

  /// Banner visible solo en modo sin cuenta (Criterio 3 y 4 de H08).
  Widget _buildBannerSinCuenta(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.shade400,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.amber.shade800,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modo sin cuenta',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tus datos no se guardarán al cerrar la app.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AuthScreen(modoVincular: true),
                      ),
                    );
                  },
                  child: Text(
                    'Crear cuenta para guardar mis datos',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildTarjetaResultado(BuildContext context, double promedio) {
    final esAprobado = CalculadoraPromedio.esAprobado(promedio);
    final color = esAprobado ? Colors.green.shade700 : Colors.red.shade700;
    final icon = esAprobado ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: esAprobado ? Colors.green.shade50 : Colors.red.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Promedio Final',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    promedio.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                esAprobado ? 'APROBADO' : 'DESAPROBADO',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
