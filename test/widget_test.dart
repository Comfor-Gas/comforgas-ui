import 'package:flutter_test/flutter_test.dart';

import 'package:comfor_gas_login/main.dart';

void main() {
  testWidgets('La pantalla de login se construye', (WidgetTester tester) async {
    await tester.pumpWidget(const ComforGasApp());

    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('INGRESAR AL SISTEMA'), findsOneWidget);
  });
}
