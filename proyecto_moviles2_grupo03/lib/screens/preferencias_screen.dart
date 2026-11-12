import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class PreferenciasScreen extends StatelessWidget {
  const PreferenciasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = Theme.of(context);
        final seleccion = themeProvider.themeMode;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Preferencias'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Personaliza tu experiencia',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona cómo deseas visualizar Pondera.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),

              Text(
                'APARIENCIA',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.light,
                      groupValue: seleccion,
                      secondary: const Icon(Icons.light_mode),
                      title: const Text('Modo claro'),
                      subtitle: const Text(
                        'Utilizar colores claros.',
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          themeProvider.cambiarTema(value);
                        }
                      },
                    ),
                    const Divider(height: 1),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.dark,
                      groupValue: seleccion,
                      secondary: const Icon(Icons.dark_mode),
                      title: const Text('Modo oscuro'),
                      subtitle: const Text(
                        'Utilizar colores oscuros.',
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          themeProvider.cambiarTema(value);
                        }
                      },
                    ),
                    const Divider(height: 1),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.system,
                      groupValue: seleccion,
                      secondary: const Icon(Icons.settings_suggest),
                      title: const Text('Según el sistema'),
                      subtitle: const Text(
                        'Adaptarse al dispositivo.',
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          themeProvider.cambiarTema(value);
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Tema seleccionado'),
                  subtitle: Text(themeProvider.nombreTema),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}