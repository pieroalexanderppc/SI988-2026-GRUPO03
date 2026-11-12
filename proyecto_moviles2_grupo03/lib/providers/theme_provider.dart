import 'package:flutter/material.dart';

/// Provider para la gestión reactiva del tema (Modo Claro, Oscuro o Sistema) (H28).
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get esOscuro => _themeMode == ThemeMode.dark;
  bool get esClaro => _themeMode == ThemeMode.light;
  bool get esSistema => _themeMode == ThemeMode.system;

  /// Cambia el modo del tema y notifica a los listeners.
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  /// Alterna entre modo claro y modo oscuro rápidamente.
  void toggleTheme(bool isDark) {
    setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}
