import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends State<EmailVerificationScreen> {
  bool _cargando = false;

  // ============================================================
  // REENVIAR CORREO DE VERIFICACIÓN
  // ============================================================

  Future<void> _reenviarCorreo() async {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return;
    }

    try {
      setState(() {
        _cargando = true;
      });

      await usuario.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Correo de verificación enviado nuevamente.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.message}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  // ============================================================
  // COMPROBAR SI EL CORREO YA FUE VERIFICADO
  // ============================================================

  Future<void> _comprobarVerificacion() async {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return;
    }

    try {
      setState(() {
        _cargando = true;
      });

      // Actualizar los datos del usuario desde Firebase
      await usuario.reload();

      final usuarioActualizado =
          FirebaseAuth.instance.currentUser;

      if (usuarioActualizado != null &&
          usuarioActualizado.emailVerified) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Correo verificado correctamente.',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Regresar al Login
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Todavía no has verificado tu correo.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ocurrió un error: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  // ============================================================
  // CERRAR SESIÓN
  // ============================================================

  Future<void> _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  // ============================================================
  // INTERFAZ
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verificación de correo',
        ),
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // ==================================================
              // ICONO
              // ==================================================

              const Icon(
                Icons.mark_email_unread,
                size: 100,
              ),

              const SizedBox(height: 30),

              // ==================================================
              // TÍTULO
              // ==================================================

              const Text(
                'Verifica tu correo',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // ==================================================
              // MENSAJE
              // ==================================================

              const Text(
                'Hemos enviado un correo de verificación '
                'a tu dirección de correo electrónico.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 15),

              // ==================================================
              // MOSTRAR CORREO
              // ==================================================

              Text(
                usuario?.email ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // INSTRUCCIONES
              // ==================================================

              const Text(
                'Revisa tu bandeja de entrada y también '
                'la carpeta de spam.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              // ==================================================
              // BOTÓN: YA VERIFIQUÉ
              // ==================================================

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _cargando
                      ? null
                      : _comprobarVerificacion,

                  icon: const Icon(
                    Icons.verified,
                  ),

                  label: const Text(
                    'Ya verifiqué mi correo',
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // BOTÓN: REENVIAR CORREO
              // ==================================================

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _cargando
                      ? null
                      : _reenviarCorreo,

                  icon: const Icon(
                    Icons.email,
                  ),

                  label: const Text(
                    'Reenviar correo',
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // VOLVER AL LOGIN
              // ==================================================

              TextButton(
                onPressed: _cargando
                    ? null
                    : _cerrarSesion,

                child: const Text(
                  'Volver al inicio de sesión',
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // CARGANDO
              // ==================================================

              if (_cargando)
                const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}