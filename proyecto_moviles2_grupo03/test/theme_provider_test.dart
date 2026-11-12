import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_moviles2_grupo03/providers/theme_provider.dart';

void main() {
  group('H28 - ThemeProvider', () {
    test('Estado inicial es ThemeMode.system', () {
      final provider = ThemeProvider();
      expect(provider.themeMode, ThemeMode.system);
      expect(provider.esSistema, isTrue);
      expect(provider.esOscuro, isFalse);
      expect(provider.esClaro, isFalse);
    });

    test('setThemeMode cambia a modo oscuro y notifica listeners', () {
      final provider = ThemeProvider();
      int notificaciones = 0;
      provider.addListener(() => notificaciones++);

      provider.setThemeMode(ThemeMode.dark);
      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.esOscuro, isTrue);
      expect(provider.esClaro, isFalse);
      expect(provider.esSistema, isFalse);
      expect(notificaciones, 1);

      // Si se asigna el mismo modo, no notifica de nuevo
      provider.setThemeMode(ThemeMode.dark);
      expect(notificaciones, 1);
    });

    test('setThemeMode cambia a modo claro y notifica listeners', () {
      final provider = ThemeProvider();
      int notificaciones = 0;
      provider.addListener(() => notificaciones++);

      provider.setThemeMode(ThemeMode.light);
      expect(provider.themeMode, ThemeMode.light);
      expect(provider.esClaro, isTrue);
      expect(provider.esOscuro, isFalse);
      expect(notificaciones, 1);
    });

    test('toggleTheme alterna correctamente entre oscuro y claro', () {
      final provider = ThemeProvider();

      provider.toggleTheme(true);
      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.esOscuro, isTrue);

      provider.toggleTheme(false);
      expect(provider.themeMode, ThemeMode.light);
      expect(provider.esClaro, isTrue);
    });
  });
}
