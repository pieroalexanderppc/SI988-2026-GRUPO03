import 'package:flutter/material.dart';
import '../models/componente_evaluacion.dart';

/// Provider para la gestión del estado dinámico de los componentes de evaluación.
class ComponentesProvider extends ChangeNotifier {
  /// Lista privada de componentes de evaluación.
  final List<ComponenteEvaluacion> _componentes = [];

  /// Contador interno para generar IDs únicos.
  int _nextId = 1;

  ComponentesProvider() {
    // Inicializar obligatoriamente con mínimo 2 filas visibles
    _inicializarFilas();
  }

  /// Retorna una copia de la lista de componentes para evitar mutaciones directas.
  List<ComponenteEvaluacion> get componentes => List.unmodifiable(_componentes);

  /// Calcula la suma total actual de los pesos ponderados.
  double get sumaPesos =>
      _componentes.fold(0.0, (sum, item) => sum + item.peso);

  /// Verifica si la suma de pesos es igual al 100% (con tolerancia de 0.1).
  bool get esSumaPesosValida => (sumaPesos - 100.0).abs() <= 0.1;

  /// Controla si es posible eliminar filas (mínimo 2 filas requeridas).
  bool get puedeEliminar => _componentes.length > 2;

  /// Inicializa la lista con 2 componentes predeterminados.
  void _inicializarFilas() {
    _componentes.add(
      ComponenteEvaluacion(
        id: _generarId(),
        nombre: 'Evaluación 1',
        nota: 0.0,
        peso: 50.0,
      ),
    );
    _componentes.add(
      ComponenteEvaluacion(
        id: _generarId(),
        nombre: 'Evaluación 2',
        nota: 0.0,
        peso: 50.0,
      ),
    );
  }

  /// Genera una clave única en formato String.
  String _generarId() {
    final id = 'comp_$_nextId';
    _nextId++;
    return id;
  }

  /// Añade una nueva fila vacía a la lista de componentes.
  void agregarComponente() {
    _componentes.add(
      ComponenteEvaluacion(
        id: _generarId(),
        nombre: '',
        nota: 0.0,
        peso: 0.0,
      ),
    );
    notifyListeners();
  }

  /// Elimina un componente por su [id], respetando el mínimo de 2 filas.
  void eliminarComponente(String id) {
    if (!puedeEliminar) return;
    _componentes.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  /// Actualiza los atributos de un componente según su [id].
  void actualizarComponente(
    String id, {
    String? nombre,
    double? nota,
    double? peso,
  }) {
    final index = _componentes.indexWhere((item) => item.id == id);
    if (index != -1) {
      _componentes[index] = _componentes[index].copyWith(
        nombre: nombre,
        nota: nota,
        peso: peso,
      );
      notifyListeners();
    }
  }
}
