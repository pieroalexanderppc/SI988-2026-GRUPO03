import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/componentes_provider.dart';
import '../widgets/fila_componente.dart';

/// Pantalla principal (HomeScreen) con el formulario dinámico de componentes de evaluación.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PromedioApp - Formulario'),
        centerTitle: true,
      ),
      body: Consumer<ComponentesProvider>(
        builder: (context, provider, child) {
          final componentes = provider.componentes;
          final sumaPesos = provider.sumaPesos;
          final esValida = provider.esSumaPesosValida;

          return Column(
            children: [
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
