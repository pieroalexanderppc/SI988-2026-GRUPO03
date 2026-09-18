import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_moviles2_grupo03/main.dart';
import 'package:proyecto_moviles2_grupo03/providers/componentes_provider.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_moviles2_grupo03/providers/auth_provider.dart';
import 'package:proyecto_moviles2_grupo03/services/auth_service.dart';
import 'package:proyecto_moviles2_grupo03/services/token_storage.dart';

// Fake implementations just to make the widget test pass
class FakeAuthService implements AuthService {
  @override
  Future<String> signIn(String email, String password) async => 'fake_token';
}

void main() {
  testWidgets('PromedioApp renderiza formulario con minimo 2 filas', (WidgetTester tester) async {
    final tokenStorage = InMemoryTokenStorage();
    await tokenStorage.writeToken('fake_token');
    
    final authProvider = AuthProvider(FakeAuthService(), tokenStorage);
    // Simulate already authenticated for tests
    // But since login requires async, we can just hack it by setting status via login
    // wait, we can't easily set status since it's private.
    // Let's just login
    await authProvider.login('test', 'test');
    
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<ComponentesProvider>(create: (_) => ComponentesProvider()),
        ],
        child: const PromedioApp(),
      ),
    );

    // Wait for frames
    await tester.pumpAndSettle();

    // Verificar que se muestre el título en la AppBar
    expect(find.text('PromedioApp - Formulario'), findsOneWidget);

    // Verificar el indicador inicial de suma de pesos (50% + 50% = 100.0%)
    expect(find.text('Suma total de pesos: 100.0%'), findsOneWidget);

    // Verificar que existen al menos 2 campos para nombre de evaluación
    expect(find.text('Evaluación 1'), findsOneWidget);
    expect(find.text('Evaluación 2'), findsOneWidget);
  });
}
