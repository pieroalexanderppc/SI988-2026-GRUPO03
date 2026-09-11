import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_moviles2_grupo03/main.dart';

void main() {
  testWidgets('PromedioApp renderiza formulario con minimo 2 filas', (WidgetTester tester) async {
    // Renderizar la aplicación PromedioApp
    await tester.pumpWidget(const PromedioApp());

    // Verificar que se muestre el título en la AppBar
    expect(find.text('PromedioApp - Formulario'), findsOneWidget);

    // Verificar el indicador inicial de suma de pesos (50% + 50% = 100.0%)
    expect(find.text('Suma total de pesos: 100.0%'), findsOneWidget);

    // Verificar que existen al menos 2 campos para nombre de evaluación
    expect(find.text('Evaluación 1'), findsOneWidget);
    expect(find.text('Evaluación 2'), findsOneWidget);
  });
}
