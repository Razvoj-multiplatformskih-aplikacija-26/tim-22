import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../presentation.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, this.mode = 'catalog', required this.failNext});

  final String mode;
  final VoidCallback failNext;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final seen = <ListingId>{};
  late ListingFilters shownFilters;
  ListingId? lastSaved;

  @override
  void initState() {
    super.initState();
    shownFilters = context.read<ListingsBloc>().state.filters;
  }

  void moveOn(CarListing listing, {required bool save}) {
    final bloc = context.read<ListingsBloc>();
    setState(() {
      seen.add(listing.id);
      lastSaved = save ? listing.id : null;
    });
    if (save) bloc.add(FavoriteSet(listing.id, true));
  }

  List<CarListing> visibleListings(ListingsState state) {
    final bloc = context.read<ListingsBloc>();
    return switch (widget.mode) {
      'favorites' => favoriteListings(state.listings, state.favorites),
      'reservations' => myReservations(state.listings, bloc.userId),
      _ => filterListings(publicListings(state.listings), filters: state.filters)
          .where((listing) => !seen.contains(listing.id)).toList(),
    };
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<ListingsBloc, ListingsState>(
    listener: (context, state) {
      if (shownFilters != state.filters) {
        setState(() {
          seen.clear();
          lastSaved = null;
          shownFilters = state.filters;
        });
      }
      showOperationError(context, state);
    },
    builder: (context, state) {
      final catalog = widget.mode == 'catalog';
      final listings = visibleListings(state);
      final title = catalog ? 'AutoMatch'
          : widget.mode == 'favorites' ? 'Favoriti' : 'Moje rezervacije';

      return Scaffold(
        appBar: AppBar(title: Text(title), actions: [
          if (catalog) IconButton(
            tooltip: 'Filteri', icon: const Icon(Icons.filter_alt),
            onPressed: () => context.push('/filters')),
          ...demoActions(context, widget.failNext),
        ]),
        body: LoadView(
          state: state,
          child: SafeArea(child: catalog
              ? catalogBody(state, listings)
              : savedBody(listings)),
        ),
      );
    },
  );

  Widget catalogBody(ListingsState state, List<CarListing> listings) {
    final bloc = context.read<ListingsBloc>();
    return Column(children: [
      Wrap(spacing: 8, children: [
        if (!state.filters.isEmpty) TextButton(
          onPressed: () => bloc.add(const FiltersChanged(ListingFilters())),
          child: const Text('Ukloni filtere')),
        if (seen.isNotEmpty) TextButton(
          onPressed: () => setState(() {
            seen.clear();
            lastSaved = null;
          }),
          child: const Text('Prikaži ponovo')),
      ]),
      if (lastSaved != null) TweenAnimationBuilder<double>(
        key: ValueKey(lastSaved!.value),
        tween: Tween(begin: 0.8, end: 1),
        duration: const Duration(milliseconds: 250),
        builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.favorite, color: Color(0xffd85055)),
          SizedBox(width: 6), Text('Sačuvano'),
        ])),
      if (listings.isEmpty)
        Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Nema više automobila za ovaj pregled.'),
          TextButton(onPressed: () => context.push('/filters'),
            child: const Text('Promeni filtere')),
        ])))
      else ...[
        Text('Još ${listings.length} u redu · levo preskoči, desno sačuvaj'),
        Expanded(child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Dismissible(
            key: ValueKey(listings.first.id.value),
            direction: DismissDirection.horizontal,
            resizeDuration: null,
            background: const ColoredBox(color: Color(0xffb8e0cc),
              child: Align(alignment: Alignment.centerLeft,
                child: Padding(padding: EdgeInsets.all(16), child: Text('SAČUVAJ')))),
            secondaryBackground: const ColoredBox(color: Color(0xffeeeeee),
              child: Align(alignment: Alignment.centerRight,
                child: Padding(padding: EdgeInsets.all(16), child: Text('PRESKOČI')))),
            onDismissed: (direction) => moveOn(listings.first,
              save: direction == DismissDirection.startToEnd),
            child: SingleChildScrollView(child: _CarCard(listing: listings.first)),
          ),
        ))),
        Padding(padding: const EdgeInsets.all(12), child: Wrap(spacing: 16, children: [
          OutlinedButton.icon(
            onPressed: () => moveOn(listings.first, save: false),
            icon: const Icon(Icons.close), label: const Text('Preskoči')),
          FilledButton.icon(
            onPressed: () => moveOn(listings.first, save: true),
            icon: const Icon(Icons.favorite), label: const Text('Sačuvaj')),
        ])),
      ],
    ]);
  }

  Widget savedBody(List<CarListing> listings) {
    if (listings.isEmpty) {
      final message = widget.mode == 'favorites'
          ? 'Još nema favorita.' : 'Nemate aktivnih rezervacija.';
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(message),
        TextButton(onPressed: () => context.go('/cars'),
          child: const Text('Otvori katalog')),
      ]));
    }

    return ListView.builder(
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final listing = listings[index];
        return _CarCard(
          listing: listing,
          removeFavorite: widget.mode == 'favorites' ? () async {
            final confirmed = await confirmRemoval(context, 'Ukloniti favorit?',
              'Ukloniti ${listing.title} iz favorita?');
            if (confirmed && mounted) {
              context.read<ListingsBloc>().add(FavoriteSet(listing.id, false));
            }
          } : null,
        );
      },
    );
  }
}

class _CarCard extends StatelessWidget {
  const _CarCard({required this.listing, this.removeFavorite});

  final CarListing listing;
  final VoidCallback? removeFavorite;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    margin: const EdgeInsets.all(12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AspectRatio(aspectRatio: 16 / 10, child: CarPhoto(listing: listing)),
      Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(listing.title, style: Theme.of(context).textTheme.headlineSmall),
          Text('${listing.priceEur} € · ${statusLabel(listing.status)}',
            style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(specSummary(listing.specs)),
          Wrap(spacing: 8, children: [
            OutlinedButton.icon(
              onPressed: () => context.push('/cars/${listing.id.value}'),
              icon: const Icon(Icons.info_outline),
              label: const Text('Pregledaj auto')),
            if (removeFavorite != null) TextButton(
              onPressed: removeFavorite, child: const Text('Ukloni favorit')),
          ]),
        ],
      )),
    ]),
  );
}
