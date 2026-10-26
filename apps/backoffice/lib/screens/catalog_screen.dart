import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../presentation.dart';
import '../widgets/listing_details.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, this.id, required this.failNext});
  final String? id;
  final VoidCallback failNext;
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}
class _CatalogScreenState extends State<CatalogScreen> {
  final search = TextEditingController();
  final searchFocus = FocusNode();
  final recordsFocus = FocusNode();
  final Map<ListingId, GlobalKey> rowKeys = {};
  bool reservedOnly = false;
  @override
  void dispose() {
    search.dispose(); searchFocus.dispose(); recordsFocus.dispose(); super.dispose();
  }
  void select(CarListing listing, {bool keyboard = false}) {
    context.go('/cars/${listing.id.value}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      recordsFocus.requestFocus();
      if (keyboard) {
        final rowContext = rowKeys[listing.id]?.currentContext;
        if (rowContext != null) Scrollable.ensureVisible(rowContext, alignment: .5);
      }
    });
  }
  KeyEventResult navigate(KeyEvent event, List<CarListing> listings) {
    if (event is! KeyDownEvent || listings.isEmpty) return KeyEventResult.ignored;
    final down = event.logicalKey == LogicalKeyboardKey.arrowDown;
    final up = event.logicalKey == LogicalKeyboardKey.arrowUp;
    if (!down && !up) return KeyEventResult.ignored;
    final index = listings.indexWhere((l) => l.id.value == widget.id);
    final next = index < 0 ? (down ? 0 : listings.length - 1)
        : (index + (down ? 1 : -1)).clamp(0, listings.length - 1).toInt();
    select(listings[next], keyboard: true);
    return KeyEventResult.handled;
  }
  @override
  Widget build(BuildContext context) => CallbackShortcuts(bindings: {
    const SingleActivator(LogicalKeyboardKey.keyN, control: true, alt: true): () => context.push('/cars/new'),
    const SingleActivator(LogicalKeyboardKey.keyF, control: true, alt: true): searchFocus.requestFocus,
  }, child: BlocConsumer<ListingsBloc, ListingsState>(listener: showOperationError,
    builder: (context, state) {
      final listings = filterListings(state.listings, query: search.text, reservedOnly: reservedOnly);
      final selected = widget.id == null ? null : findListing(state.listings, ListingId(widget.id!));
      return Scaffold(appBar: AppBar(title: const Text('AutoMatch · Osoblje'),
        actions: demoActions(context, widget.failNext)),
        body: LoadView(state: state, child: Column(children: [
          Padding(padding: const EdgeInsets.all(12), child: Wrap(spacing: 12, runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center, children: [
              SizedBox(width: 260, child: TextField(controller: search, focusNode: searchFocus,
                onChanged: (_) => setState(() {}), decoration: const InputDecoration(
                  labelText: 'Pretraga · Ctrl+Alt+F', prefixIcon: Icon(Icons.search)))),
              FilterChip(label: const Text('Samo rezervisani'), selected: reservedOnly,
                onSelected: (value) => setState(() => reservedOnly = value)),
              FilledButton(onPressed: state.saving ? null : () => context.push('/cars/new'),
                child: const Text('Novi oglas · Ctrl+Alt+N')),
            ])),
          Expanded(child: LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final records = Focus(focusNode: recordsFocus, autofocus: true,
              onKeyEvent: (_, event) => navigate(event, listings),
              child: AnimatedBuilder(animation: recordsFocus, builder: (context, child) => DecoratedBox(
                decoration: BoxDecoration(border: Border.all(width: 2,
                  color: recordsFocus.hasFocus ? Theme.of(context).colorScheme.primary : Colors.transparent)),
                child: child), child: listings.isEmpty ? const Center(child: Text('Nema oglasa za ovaj filter.'))
                  : SingleChildScrollView(child: wide ? SingleChildScrollView(scrollDirection: Axis.horizontal,
                    child: DataTable(showCheckboxColumn: false, dataRowMaxHeight: double.infinity,
                      columns: const [DataColumn(label: Text('Naziv')), DataColumn(label: Text('Cena')),
                        DataColumn(label: Text('Status'))], rows: [
                        for (final listing in listings) DataRow(selected: listing.id.value == widget.id,
                          onSelectChanged: (_) => select(listing), cells: [
                            DataCell(TextButton(key: rowKeys.putIfAbsent(listing.id, GlobalKey.new),
                              onPressed: () => select(listing), child: Text(listing.title))),
                            DataCell(Text('${listing.priceEur} €')), DataCell(Text(statusLabel(listing.status))),
                          ]),
                      ])) : Column(children: [
                        for (final listing in listings) Padding(padding: const EdgeInsets.all(4),
                          child: OutlinedButton(key: rowKeys.putIfAbsent(listing.id, GlobalKey.new),
                            style: OutlinedButton.styleFrom(backgroundColor: listing.id.value == widget.id
                              ? Theme.of(context).colorScheme.secondaryContainer : null),
                            onPressed: () => select(listing), child: SizedBox(width: double.infinity,
                              child: Padding(padding: const EdgeInsets.all(12), child: Text(
                                '${listing.title}\n${listing.priceEur} € · ${statusLabel(listing.status)}'))))),
                      ]))));
            final details = selected == null ? Center(child: Text(widget.id == null
              ? 'Izaberite oglas.' : 'Oglas nije dostupan')) : Column(children: [
                if (!listings.any((l) => l.id == selected.id)) const Text('Izbor je van trenutnog filtera.'),
                Expanded(child: ListingDetails(listing: selected, state: state)),
              ]);
            return wide ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(flex: 3, child: records), const VerticalDivider(width: 1),
              Expanded(flex: 2, child: details),
            ]) : Column(children: [Expanded(child: records), const Divider(height: 1),
              Expanded(child: details)]);
          })),
        ])));
    }));
}
