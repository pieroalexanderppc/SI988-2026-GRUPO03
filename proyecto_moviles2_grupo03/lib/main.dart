import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/componentes_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PromedioApp());
}

/// Widget raíz de la aplicación PromedioApp.
class PromedioApp extends StatelessWidget {
  const PromedioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ComponentesProvider(),
      child: MaterialApp(
        title: 'PromedioApp',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.light,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
