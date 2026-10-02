import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _esRegistro = false;
  bool _cargando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _autenticar() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _mostrarError('Ingresa un correo válido');
      return;
    }

    if (password.length < 6) {
      _mostrarError(
        'La contraseña debe tener mínimo 6 caracteres',
      );
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      if (_esRegistro) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String mensaje;

      switch (e.code) {
        case 'user-not-found':
          mensaje = 'No existe una cuenta con ese correo';
          break;

        case 'wrong-password':
        case 'invalid-credential':
          mensaje = 'Correo o contraseña incorrectos';
          break;

        case 'email-already-in-use':
          mensaje = 'El correo ya está registrado';
          break;

        case 'invalid-email':
          mensaje = 'El correo no es válido';
          break;

        case 'weak-password':
          mensaje = 'La contraseña debe tener mínimo 6 caracteres';
          break;

        default:
          mensaje = 'Ocurrió un error: ${e.message}';
      }

      _mostrarError(mensaje);
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _esRegistro
              ? 'Crear cuenta'
              : 'Iniciar sesión',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_circle,
                size: 90,
              ),

              const SizedBox(height: 30),

              Text(
                _esRegistro
                    ? 'Crear una cuenta'
                    : 'Bienvenido',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall,
              ),

              const SizedBox(height: 25),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cargando
                      ? null
                      : _autenticar,
                  child: _cargando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(),
                        )
                      : Text(
                          _esRegistro
                              ? 'Crear cuenta'
                              : 'Iniciar sesión',
                        ),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: _cargando
                    ? null
                    : () {
                        setState(() {
                          _esRegistro = !_esRegistro;
                        });
                      },
                child: Text(
                  _esRegistro
                      ? '¿Ya tienes una cuenta? Inicia sesión'
                      : '¿No tienes cuenta? Crear una',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}