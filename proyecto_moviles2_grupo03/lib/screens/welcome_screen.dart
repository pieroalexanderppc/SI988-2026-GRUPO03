import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.waving_hand,
                size: 90,
              ),

              const SizedBox(height: 30),

              Text(
                user != null
                    ? '¡Bienvenido de nuevo!'
                    : '¡Bienvenido!',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 15),

              if (user != null)
                Text(
                  user.email ?? 'Usuario',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge,
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 35),

              if (user != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const HomeScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Continuar',
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();

                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const WelcomeScreen(),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Cerrar sesión',
                  ),
                ),
              ],

              if (user == null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Iniciar sesión / Crear cuenta',
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const HomeScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Continuar sin cuenta',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}