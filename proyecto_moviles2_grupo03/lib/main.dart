import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/componentes_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/token_storage.dart';
import 'network/api_client.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final tokenStorage = SecureTokenStorage();
  final authService = FirebaseAuthService();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthProvider(authService, tokenStorage),
        ),
        ChangeNotifierProvider(
          create: (context) => ComponentesProvider(),
        ),
        Provider<ApiClient>(
          create: (context) => ApiClient(
            tokenStorage,
            onUnauthorized: () {
              // Limpiar authProvider
              context.read<AuthProvider>().logout();
              // Redirigir al login
              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ),
      ],
      child: const PromedioApp(),
    ),
  );
}

class PromedioApp extends StatelessWidget {
  const PromedioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'PromedioApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.status == AuthStatus.authenticated) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
