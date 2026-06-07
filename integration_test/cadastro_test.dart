import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pantry/app.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUp(() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('overflowed')) return;
      previous?.call(details);
    };
  });

  testWidgets('cadastra produto no estoque', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    await initializeDateFormatting('pt_BR', null);

    runApp(const ProviderScope(child: PantryApp()));
    await tester.pumpAndSettle(const Duration(seconds: 20));

    expect(find.textContaining('Erro ao abrir'), findsNothing);
    expect(find.text('Minha despensa'), findsOneWidget);

    await tester.tap(find.text('Estoque'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cadastrar produto'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Arroz');
    await tester.enterText(find.byType(TextField).at(1), '2');

    await tester.scrollUntilVisible(
      find.text('Criar item'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Criar item'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('Nenhum produto cadastrado'), findsNothing);
    expect(find.text('Arroz'), findsWidgets);
  });
}
