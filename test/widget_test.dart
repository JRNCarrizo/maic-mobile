import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maic_mobile/app/app.dart';
import 'package:maic_mobile/app/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('arranca en la pantalla de conexión', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaicApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MAIC'), findsOneWidget);
    expect(find.text('demo@demo'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.text('Probar y guardar'), findsNothing);

    await tester.tap(find.text('Servidor'));
    await tester.pumpAndSettle();
    expect(find.text('Probar y guardar'), findsOneWidget);
  });
}
