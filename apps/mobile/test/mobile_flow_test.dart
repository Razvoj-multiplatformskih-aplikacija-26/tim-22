import 'package:automatch_mobile/main.dart';
import 'package:automatch_mobile/data/memory_listings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> start(WidgetTester tester) async {
  final repository = MemoryListingsRepository(delay: Duration.zero);
  await tester.pumpWidget(MobileApp(repository: repository, failNext: repository.failNextRequest));
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('combined filters show one matching car and survive reopening', (tester) async {
    await start(tester);
    await tap(tester, find.byTooltip('Filteri'));
    await tester.enterText(find.byType(TextFormField), '23000');
    await tap(tester, find.byKey(const ValueKey('Boja')));
    await tap(tester, find.text('Crvena').last);
    await tap(tester, find.byKey(const ValueKey('Menjač')));
    await tap(tester, find.text('Automatski').last);
    await tap(tester, find.text('Primeni'));
    expect(find.byType(Dismissible), findsOneWidget);
    expect(find.text('Mazda CX-5 2021'), findsOneWidget);
    expect(find.text('Toyota Yaris 2019'), findsNothing);
    await tap(tester, find.byTooltip('Filteri'));
    expect(tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text, '23000');
    expect(tester.widget<DropdownButtonFormField<String>>(
      find.byKey(const ValueKey('Boja'))).initialValue, 'Crvena');
    await tap(tester, find.text('Ukloni filtere'));
    expect(find.text('Toyota Yaris 2019'), findsOneWidget);
  });

  testWidgets('skipping the queue reaches an end and replay restores one card', (tester) async {
    await start(tester);
    for (var i = 0; i < 10; i++) {
      expect(find.byType(Dismissible), findsOneWidget);
      await tap(tester, find.text('Preskoči'));
    }
    expect(find.byType(Dismissible), findsNothing);
    expect(find.text('Nema više automobila za ovaj pregled.'), findsOneWidget);
    await tap(tester, find.text('Prikaži ponovo'));
    expect(find.byType(Dismissible), findsOneWidget);
    expect(find.text('Toyota Yaris 2019'), findsOneWidget);
  });

  testWidgets('saving the final car still shows feedback', (tester) async {
    await start(tester);
    for (var i = 0; i < 9; i++) {
      await tap(tester, find.text('Preskoči'));
    }
    await tap(tester, find.text('Sačuvaj').last);
    expect(find.text('Sačuvano'), findsOneWidget);
    expect(find.text('Nema više automobila za ovaj pregled.'), findsOneWidget);
  });

  testWidgets('budget validates, detail reserves and own reservations update', (tester) async {
    await start(tester);
    await tap(tester, find.byTooltip('Filteri'));
    for (final invalid in ['0', '-1', 'text']) {
      await tester.enterText(find.byType(TextFormField), invalid);
      await tap(tester, find.text('Primeni'));
      expect(find.text('Unesite pozitivan ceo iznos u evrima.'), findsOneWidget);
    }
    await tester.enterText(find.byType(TextFormField), '1');
    await tap(tester, find.text('Primeni'));
    expect(find.text('Nema više automobila za ovaj pregled.'), findsOneWidget);
    await tap(tester, find.text('Ukloni filtere'));
    await tap(tester, find.text('Pregledaj auto').first);
    await tap(tester, find.text('Rezerviši'));
    expect(find.textContaining('Rezervisano'), findsOneWidget);
    await tap(tester, find.byTooltip('Katalog'));
    await tap(tester, find.text('Moje rezervacije').last);
    expect(find.text('Toyota Yaris 2019'), findsOneWidget);
    await tap(tester, find.text('Pregledaj auto').first);
    await tap(tester, find.text('Otkaži rezervaciju'));
    expect(find.text('Otkazati rezervaciju?'), findsOneWidget);
    await tap(tester, find.text('Odustani'));
    expect(find.textContaining('Rezervisano'), findsOneWidget);
    await tap(tester, find.text('Otkaži rezervaciju'));
    await tap(tester, find.text('Potvrdi'));
    expect(find.textContaining('Aktivan'), findsOneWidget);
  });

  testWidgets('swipe removes its card immediately and saves exactly one favorite', (tester) async {
    await start(tester);
    expect(find.byType(Dismissible), findsOneWidget);
    expect(find.text('Renault Clio 2018'), findsNothing);
    await tester.drag(find.byType(Dismissible), const Offset(800, 0));
    await tester.pumpAndSettle();
    expect(find.text('Sačuvano'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
    expect(find.text('Toyota Yaris 2019'), findsNothing);
    expect(find.text('Renault Clio 2018'), findsOneWidget);
    expect(find.byType(Dismissible), findsOneWidget);
    await tap(tester, find.text('Prikaži ponovo'));
    await tap(tester, find.text('Sačuvaj').first);
    await tap(tester, find.text('Favoriti').last);
    expect(find.text('Toyota Yaris 2019'), findsOneWidget);
    expect(find.text('Ukloni favorit'), findsOneWidget);
    await tap(tester, find.text('Ukloni favorit'));
    expect(find.text('Ukloniti favorit?'), findsOneWidget);
    await tap(tester, find.text('Odustani'));
    expect(find.text('Toyota Yaris 2019'), findsOneWidget);
    await tap(tester, find.text('Ukloni favorit'));
    await tap(tester, find.text('Potvrdi'));
    expect(find.text('Toyota Yaris 2019'), findsNothing);
  });

  testWidgets('details are available before swipe and saved car opens a local chat', (tester) async {
    await start(tester);
    await tap(tester, find.text('Pregledaj auto'));
    expect(find.text('Marka'), findsOneWidget);
    expect(find.text('Kilometraža'), findsOneWidget);
    expect(find.text('85000 km'), findsOneWidget);
    await tap(tester, find.text('Sačuvaj favorit'));
    expect(find.byType(AlertDialog), findsNothing);
    await tap(tester, find.text('Demo chat'));
    expect(find.textContaining('poruke se ne šalju vlasniku'), findsOneWidget);
    await tap(tester, find.text('Mogu li da zakažem razgledanje?'));
    expect(find.text('Mogu li da zakažem razgledanje?'), findsNWidgets(2));
    await tester.enterText(find.byType(TextField), 'Da li je cena fiksna?');
    await tap(tester, find.byTooltip('Dodaj poruku u demo chat'));
    expect(find.text('Da li je cena fiksna?'), findsOneWidget);
  });

  testWidgets('removing a favorite from details requires confirmation', (tester) async {
    await start(tester);
    await tap(tester, find.text('Pregledaj auto'));
    await tap(tester, find.text('Sačuvaj favorit'));
    await tap(tester, find.text('Ukloni favorit'));
    expect(find.text('Ukloniti favorit?'), findsOneWidget);
    await tap(tester, find.text('Odustani'));
    expect(find.text('Ukloni favorit'), findsOneWidget);
    await tap(tester, find.text('Ukloni favorit'));
    await tap(tester, find.text('Potvrdi'));
    expect(find.text('Sačuvaj favorit'), findsOneWidget);
  });

  testWidgets('brand, mileage and year filters combine', (tester) async {
    await start(tester);
    await tap(tester, find.byTooltip('Filteri'));
    await tester.enterText(find.byType(TextFormField).at(1), '70000');
    await tester.enterText(find.byType(TextFormField).at(2), '2020');
    await tap(tester, find.byKey(const ValueKey('Marka')));
    await tap(tester, find.text('Hyundai').last);
    await tap(tester, find.text('Primeni'));
    expect(find.text('Hyundai i30 2021'), findsOneWidget);
    expect(find.text('Toyota Yaris 2019'), findsNothing);
  });

  testWidgets('demo error supports retry', (tester) async {
    await start(tester);
    await tap(tester, find.byTooltip('Demo kontrole'));
    await tap(tester, find.text('Izazovi grešku sledećeg zahteva'));
    await tap(tester, find.byTooltip('Osveži'));
    expect(find.text('Učitavanje nije uspelo.'), findsOneWidget);
    await tap(tester, find.text('Pokušaj ponovo'));
    expect(find.text('Toyota Yaris 2019'), findsOneWidget);
  });
}
