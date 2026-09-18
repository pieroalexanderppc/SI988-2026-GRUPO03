import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/validators.dart';
import '../network/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthProvider>().login(
        _emailController.text,
        _passwordController.text,
      );
    }
  }

  void _simulate401() async {
    try {
      final apiClient = context.read<ApiClient>();
      await apiClient.simulate401Request();
    } catch (e) {
      // Ignorar, el interceptor ya debe haber manejado el 401
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = context.select((AuthProvider p) => p.status);
    final errorMessage = context.select((AuthProvider p) => p.errorMessage);
    final isLoading = authStatus == AuthStatus.loading;
    final isLocked = authStatus == AuthStatus.locked;

    final isValid = Validators.validateEmail(_emailController.text) == null && 
                    Validators.validatePassword(_passwordController.text) == null;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_person, size: 64, color: Colors.indigo),
                      const SizedBox(height: 16),
                      const Text(
                        'Iniciar Sesión',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      if (errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isLocked ? Colors.red.shade100 : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isLocked ? Colors.red.shade300 : Colors.orange.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isLocked ? Icons.block : Icons.error_outline,
                                color: isLocked ? Colors.red.shade900 : Colors.orange.shade900,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage,
                                  style: TextStyle(
                                    color: isLocked ? Colors.red.shade900 : Colors.orange.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (errorMessage != null) const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isLoading,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: Validators.validateEmail,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        obscureText: true,
                        enabled: !isLoading,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: Validators.validatePassword,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: (isLoading || !isValid) ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Ingresar', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        TextButton.icon(
                          onPressed: _simulate401,
                          icon: const Icon(Icons.bug_report, size: 18),
                          label: const Text('Simular Error 401'),
                          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
                        )
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
