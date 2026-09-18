import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/usuario_model.dart';
import 'providers/componentes_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Modo offline resiliente para garantizar ejecución continua
  }

  // Flujo de arranque: Verificar persistencia local y Auto-Login (Punto 1)
  final authService = AuthService();
  final bool estaAutenticado = await authService.estaAutenticado();
  final UsuarioModel? usuario = estaAutenticado
      ? await authService.obtenerUsuarioActual()
      : null;

  runApp(
    PromedioApp(estaAutenticado: estaAutenticado, usuarioInicial: usuario),
  );
}

/// Widget raíz de la aplicación PromedioApp con soporte de Auto-Login.
class PromedioApp extends StatelessWidget {
  final bool estaAutenticado;
  final UsuarioModel? usuarioInicial;

  const PromedioApp({
    super.key,
    this.estaAutenticado = false,
    this.usuarioInicial,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ComponentesProvider(),
      child: MaterialApp(
        title: 'PromedioApp - UPT',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.light,
          ),
        ),
        // Si hay token persistido salta directo a HomeScreen; si no, muestra LoginScreen
        home: estaAutenticado
            ? HomeScreen(usuario: usuarioInicial)
            : const LoginScreen(),
      ),
    );
  }
}
