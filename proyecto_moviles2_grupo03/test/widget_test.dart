import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_moviles2_grupo03/screens/home_screen.dart';
import 'package:proyecto_moviles2_grupo03/providers/componentes_provider.dart';

void main() {
  testWidgets('PromedioApp renderiza formulario con minimo 2 filas', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => ComponentesProvider(),
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    expect(find.text('PromedioApp - Formulario'), findsOneWidget);
    expect(find.text('Suma total de pesos: 100.0%'), findsOneWidget);
    expect(find.text('Evaluación 1'), findsOneWidget);
    expect(find.text('Evaluación 2'), findsOneWidget);
  });
}
