import 'package:automatch_backoffice/main.dart';
import 'package:automatch_backoffice/data/memory_listings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> start(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repository = MemoryListingsRepository(delay: Duration.zero);
  await tester.pumpWidget(BackofficeApp(repository: repository, failNext: repository.failNextRequest));
  await tester.pumpAndSettle();
}
Future<void> shortcut(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('selection survives resizing; arrows and shortcuts work', (tester) async {
    await start(tester);
    await shortcut(tester, LogicalKeyboardKey.keyF);
    expect(tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus, isTrue);
    await tester.tap(find.text('Toyota Yaris 2019'));
    await tester.pumpAndSettle();
    expect(find.text('Detalj · car-1'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('Detalj · car-2'), findsOneWidget);
    tester.view.physicalSize = const Size(700, 900);
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsNothing);
    expect(find.text('Detalj · car-2'), findsOneWidget);
    await shortcut(tester, LogicalKeyboardKey.keyF);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode!.hasFocus, isTrue);
    await tester.enterText(find.byType(TextField), 'Toyota');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('Detalj · car-2'), findsOneWidget);
    await shortcut(tester, LogicalKeyboardKey.keyN);
    expect(find.text('Novi oglas'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Demo car');
    await tester.enterText(find.byType(TextFormField).at(1), '500');
    await tester.tap(find.text('Sačuvaj'));
    await tester.pumpAndSettle();
    expect(find.text('Detalj · new-1'), findsOneWidget);
    await tester.ensureVisible(find.text('Objavi'));
    expect(find.text('Otkaži rezervaciju'), findsNothing);
    await tester.tap(find.text('Objavi'));
    await tester.pumpAndSettle();
    expect(find.textContaining('500 € · Aktivan'), findsWidgets);
    expect(find.text('Objavi'), findsNothing);
    expect(find.text('Otkaži rezervaciju'), findsNothing);
  });

  testWidgets('sale requires explicit confirmation and Escape cancels', (tester) async {
    await start(tester);
    await tester.tap(find.text('Samo rezervisani'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kia Ceed 2020'));
    await tester.pumpAndSettle();
    expect(find.text('Objavi'), findsNothing);
    expect(find.text('Otkaži rezervaciju'), findsOneWidget);
    await tester.ensureVisible(find.text('Označi kao prodato'));
    await tester.tap(find.text('Označi kao prodato'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Odustani'));
    await tester.pumpAndSettle();
    expect(find.text('13500 € · Rezervisano'), findsOneWidget);
    await tester.ensureVisible(find.text('Označi kao prodato'));
    await tester.tap(find.text('Označi kao prodato'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('13500 € · Rezervisano'), findsOneWidget);
    await tester.ensureVisible(find.text('Označi kao prodato'));
    await tester.tap(find.text('Označi kao prodato'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Potvrdi'));
    await tester.pumpAndSettle();
    expect(find.text('13500 € · Prodato'), findsOneWidget);
    expect(find.text('Izbor je van trenutnog filtera.'), findsOneWidget);
  });

  testWidgets('cancel reservation confirms and never publishes a reserved car', (tester) async {
    await start(tester);
    await tester.tap(find.text('Kia Ceed 2020'));
    await tester.pumpAndSettle();
    expect(find.text('Objavi'), findsNothing);
    await tester.ensureVisible(find.text('Otkaži rezervaciju'));
    await tester.tap(find.text('Otkaži rezervaciju'));
    await tester.pumpAndSettle();
    expect(find.text('Otkazati rezervaciju?'), findsOneWidget);
    await tester.tap(find.text('Odustani'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Rezervisano'), findsWidgets);
    await tester.tap(find.text('Otkaži rezervaciju'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Potvrdi'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Aktivan'), findsWidgets);
    expect(find.text('Otkaži rezervaciju'), findsNothing);
  });
}
