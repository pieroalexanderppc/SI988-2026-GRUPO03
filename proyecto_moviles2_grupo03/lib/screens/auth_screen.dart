import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/validators.dart';
import 'home_screen.dart';
import 'email_verification_screen.dart';

class AuthScreen extends StatefulWidget {
  final bool modoVincular;

  const AuthScreen({
    super.key,
    this.modoVincular = false,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _esRegistro = false;
  bool _cargando = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // MENSAJES DE ERROR
  // ============================================================

  String _mapErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No se encontró una cuenta con este correo.';

      case 'wrong-password':
        return 'La contraseña es incorrecta.';

      case 'email-already-in-use':
        return 'Este correo ya está registrado.';

      case 'invalid-email':
        return 'El formato del correo es inválido.';

      case 'weak-password':
        return 'La contraseña es muy débil (mínimo 6 caracteres).';

      case 'invalid-credential':
        return 'Las credenciales proporcionadas son inválidas o incorrectas.';

      case 'too-many-requests':
        return 'Demasiados intentos. Intenta nuevamente más tarde.';

      case 'network-request-failed':
        return 'No hay conexión a Internet.';

      default:
        return 'Ocurrió un error. Por favor, intenta de nuevo.';
    }
  }

  // ============================================================
  // LOGIN / REGISTRO
  // ============================================================

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      // ========================================================
      // REGISTRO
      // ========================================================

      if (_esRegistro) {
        final credencial = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );

        final usuario = credencial.user;

        if (usuario != null) {
          // Enviar correo de verificación
          await usuario.sendEmailVerification();

          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const EmailVerificationScreen(),
              ),
            );
          }
        }
      }

      // ========================================================
      // INICIO DE SESIÓN
      // ========================================================

      else {
        final credencial = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );

        final usuario = credencial.user;

        if (usuario != null) {
          // Actualizar datos del usuario
          await usuario.reload();

          final usuarioActualizado =
              FirebaseAuth.instance.currentUser;

          // ====================================================
          // COMPROBAR CORREO VERIFICADO
          // ====================================================

          if (usuarioActualizado != null &&
              !usuarioActualizado.emailVerified) {
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const EmailVerificationScreen(),
                ),
              );
            }

            return;
          }

          // ====================================================
          // CORREO VERIFICADO → INGRESAR
          // ====================================================

          if (mounted) {
            if (widget.modoVincular) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const HomeScreen(),
                ),
              );
            }
          }
        }
      }
    }

    // ==========================================================
    // ERRORES FIREBASE
    // ==========================================================

    on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _mapErrorMessage(e.code),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    // ==========================================================
    // OTROS ERRORES
    // ==========================================================

    catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error inesperado: $e',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    // ==========================================================
    // FINALIZAR CARGA
    // ==========================================================

    finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  // ============================================================
  // INTERFAZ
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(
            milliseconds: 300,
          ),
          child: Text(
            _esRegistro
                ? 'Crear cuenta'
                : 'Iniciar sesión',
            key: ValueKey<bool>(_esRegistro),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),

          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 400,
            ),

            child: Form(
              key: _formKey,

              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [
                  // ==================================================
                  // ICONO
                  // ==================================================

                  Hero(
                    tag: 'app_icon',
                    child: Container(
                      padding:
                          const EdgeInsets.all(24),

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                      ),

                      child: Icon(
                        Icons.school_rounded,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .primary,

                        semanticLabel:
                            'Icono de seguridad',
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // ==================================================
                  // CORREO
                  // ==================================================

                  TextFormField(
                    controller: _emailCtrl,

                    keyboardType:
                        TextInputType.emailAddress,

                    decoration:
                        const InputDecoration(
                      labelText:
                          'Correo electrónico',

                      prefixIcon: Icon(
                        Icons.email_outlined,
                      ),
                    ),

                    validator: Validators.email,
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // CONTRASEÑA
                  // ==================================================

                  TextFormField(
                    controller: _passCtrl,

                    obscureText: true,

                    decoration:
                        const InputDecoration(
                      labelText: 'Contraseña',

                      prefixIcon: Icon(
                        Icons.lock_outline,
                      ),
                    ),

                    validator: Validators.password,
                  ),

                  const SizedBox(height: 32),

                  // ==================================================
                  // BOTONES
                  // ==================================================

                  AnimatedSwitcher(
                    duration: const Duration(
                      milliseconds: 300,
                    ),

                    child: _cargando
                        ? const CircularProgressIndicator()
                        : Column(
                            key: const ValueKey(
                              'buttons',
                            ),

                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,

                            children: [
                              FilledButton(
                                onPressed: _submit,

                                child: Text(
                                  _esRegistro
                                      ? 'Registrarse'
                                      : 'Ingresar',
                                ),
                              ),

                              const SizedBox(height: 16),

                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _esRegistro =
                                        !_esRegistro;

                                    _formKey
                                        .currentState
                                        ?.reset();
                                  });
                                },

                                child: Text(
                                  _esRegistro
                                      ? '¿Ya tienes cuenta? Inicia sesión'
                                      : '¿No tienes cuenta? Regístrate',
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}