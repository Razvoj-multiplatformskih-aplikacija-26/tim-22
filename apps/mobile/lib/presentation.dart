import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

ThemeData appTheme() => ThemeData(useMaterial3: true, fontFamily: 'AutoMatch',
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff123c36)));

String statusLabel(ListingStatus status) => switch (status) {
  Draft() => 'Nacrt', Active() => 'Aktivan', Reserved() => 'Rezervisano',
  Sold() => 'Prodato', Withdrawn() => 'Povučen',
};
String actionLabel(ListingAction action) => switch (action) {
  ListingAction.publish => 'Objavi', ListingAction.reserve => 'Rezerviši',
  ListingAction.cancelReservation => 'Otkaži rezervaciju',
  ListingAction.sell => 'Označi kao prodato', ListingAction.withdraw => 'Povuci',
};
String errorLabel(DomainError error) => switch (error) {
  InvalidPrice() => 'Unesite pozitivan ceo iznos u evrima.',
  InvalidNumber() => 'Unesite pozitivan ceo broj.',
  EmptyTitle() => 'Unesite naziv vozila.',
  ListingNotFound() => 'Oglas nije dostupan.',
  ListingUnavailable() => 'Vozilo više nije dostupno za rezervaciju.',
  ForbiddenAction() => 'Nemate pravo na ovu akciju.',
  InvalidTransition() => 'Promena statusa nije dozvoljena.',
};
String? priceError(String? text) => switch (validatePrice(int.tryParse(text?.trim() ?? ''))) {
  Failure<int>(:final error) => errorLabel(error), Success<int>() => null,
};
String? numberError(String? text) => text == null || text.trim().isEmpty ? null
  : switch (validatePositiveNumber(int.tryParse(text.trim()))) {
      Failure<int>(:final error) => errorLabel(error), Success<int>() => null,
    };

void showOperationError(BuildContext context, ListingsState state) {
  final message = state.domainError != null ? errorLabel(state.domainError!)
      : state.repositoryError ? 'Zahtev nije uspeo. Pokušajte ponovo.' : null;
  if (message != null && state.status != LoadStatus.failure) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class LoadView extends StatelessWidget {
  const LoadView({super.key, required this.state, required this.child});
  final ListingsState state;
  final Widget child;
  @override
  Widget build(BuildContext context) => switch (state.status) {
    LoadStatus.loading => const Center(child: Column(mainAxisSize: MainAxisSize.min,
      children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Učitavanje oglasa…')])),
    LoadStatus.failure => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Učitavanje nije uspelo.'),
      FilledButton(onPressed: () => context.read<ListingsBloc>().add(const LoadRequested()),
        child: const Text('Pokušaj ponovo')),
    ])),
    LoadStatus.ready => child,
  };
}

List<Widget> demoActions(BuildContext context, VoidCallback failNext) => [
  IconButton(tooltip: 'Osveži', icon: const Icon(Icons.refresh),
    onPressed: () => context.read<ListingsBloc>().add(const LoadRequested())),
  PopupMenuButton<String>(tooltip: 'Demo kontrole', onSelected: (_) {
    failNext();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Sledeći zahtev će biti neuspešan. Pritisnite Osveži.')));
  }, itemBuilder: (_) => [const PopupMenuItem(value: 'fail',
    child: Text('Izazovi grešku sledećeg zahteva'))]),
];

String specSummary(CarSpecs specs) => [
  [specs.brand, specs.model].where((value) => value.isNotEmpty).join(' '),
  if (specs.year > 0) '${specs.year}. godište',
  if (specs.mileageKm > 0) '${specs.mileageKm} km',
  specs.bodyType, specs.drive,
  if (specs.doors.isNotEmpty) '${specs.doors} vrata', specs.color,
  specs.transmission,
  if (specs.gears.isNotEmpty) specs.gears == 'CVT' ? 'CVT' : '${specs.gears} brzina',
  specs.fuel,
].where((value) => value.isNotEmpty).join(' · ');

class CarPhoto extends StatelessWidget {
  const CarPhoto({super.key, required this.listing});
  final CarListing listing;
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
    Image.asset(listing.imageAsset, fit: BoxFit.contain,
      semanticLabel: 'Fotografija: ${listing.title}',
      errorBuilder: (_, _, _) => const Center(child: Text('Fotografija nije dostupna'))),
    const Positioned(right: 8, bottom: 8, child: DecoratedBox(
      decoration: BoxDecoration(color: Colors.black54),
      child: Padding(padding: EdgeInsets.all(4), child: Text('Demo fotografija',
        style: TextStyle(color: Colors.white, fontSize: 11))))),
  ]);
}

Future<bool> confirmRemoval(BuildContext context, String title, String message) async =>
  await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      TextButton(onPressed: () => Navigator.pop(dialogContext, false),
        child: const Text('Odustani')),
      FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
        child: const Text('Potvrdi')),
    ],
  )) ?? false;
