import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'preferencia_tema';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _cargarPreferencia();
  }

  Future<void> _cargarPreferencia() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final temaGuardado = prefs.getString(_themeKey);

      switch (temaGuardado) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar el tema: $e');
    }
  }

  Future<void> cambiarTema(ThemeMode nuevoTema) async {
    _themeMode = nuevoTema;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      String valor;

      switch (nuevoTema) {
        case ThemeMode.light:
          valor = 'light';
          break;
        case ThemeMode.dark:
          valor = 'dark';
          break;
        case ThemeMode.system:
          valor = 'system';
          break;
      }

      await prefs.setString(_themeKey, valor);
    } catch (e) {
      debugPrint('Error al guardar el tema: $e');
    }
  }

  String get nombreTema {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Modo claro';
      case ThemeMode.dark:
        return 'Modo oscuro';
      case ThemeMode.system:
        return 'Según el sistema';
    }
  }
}