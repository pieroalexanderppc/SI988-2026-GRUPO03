import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/firebase_auth_repository.dart';
import '../services/login_use_case.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _correoController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final FirebaseAuthRepository _repository =
      FirebaseAuthRepository();

  bool _esRegistro = false;
  bool _mostrarPassword = false;
  bool _cargando = false;

  String? _error;

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _autenticar() async {
    setState(() {
      _error = null;
      _cargando = true;
    });

    try {
      final useCase = LoginUseCase(_repository);

      if (_esRegistro) {
        await useCase.registrar(
          _correoController.text,
          _passwordController.text,
        );
      } else {
        await useCase.ejecutar(
          _correoController.text,
          _passwordController.text,
        );
      }

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/home',
      );
    } on ArgumentError catch (e) {
      setState(() {
        _error = e.message.toString();
      });
    } on FirebaseAuthException catch (e) {
      print('ERROR FIREBASE: ${e.code}');
      print('MENSAJE FIREBASE: ${e.message}');

      setState(() {
        _error = '${e.code}: ${e.message}';
      });
    } catch (e) {
      print('ERROR GENERAL: $e');

      setState(() {
        _error = 'Ocurrió un error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
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
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 450,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.account_circle,
                  size: 90,
                ),

                const SizedBox(height: 24),

                Text(
                  _esRegistro
                      ? 'Crear una cuenta'
                      : 'Iniciar sesión',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall,
                ),

                const SizedBox(height: 24),

                TextField(
                  controller: _correoController,
                  keyboardType:
                      TextInputType.emailAddress,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(
                      RegExp(r'\s'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon:
                        Icon(Icons.email),
                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller:
                      _passwordController,
                  obscureText:
                      !_mostrarPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon:
                        const Icon(Icons.lock),
                    border:
                        const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _mostrarPassword =
                              !_mostrarPassword;
                        });
                      },
                      icon: Icon(
                        _mostrarPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                if (_error != null)
                  Container(
                    padding:
                        const EdgeInsets.all(12),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.red.shade50,
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color:
                            Colors.red.shade800,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                FilledButton(
                  onPressed: _cargando
                      ? null
                      : _autenticar,
                  child: _cargando
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child:
                              CircularProgressIndicator(),
                        )
                      : Text(
                          _esRegistro
                              ? 'Crear cuenta'
                              : 'Iniciar sesión',
                        ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: _cargando
                      ? null
                      : () {
                          setState(() {
                            _esRegistro =
                                !_esRegistro;
                            _error = null;
                          });
                        },
                  child: Text(
                    _esRegistro
                        ? '¿Ya tienes cuenta? Iniciar sesión'
                        : '¿No tienes cuenta? Registrarte',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}