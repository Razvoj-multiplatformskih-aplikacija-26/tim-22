import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../presentation.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) => BlocConsumer<ListingsBloc, ListingsState>(
    listener: showOperationError, builder: (context, state) {
      final bloc = context.read<ListingsBloc>();
      final listing = findListing(state.listings, ListingId(id));
      return Scaffold(appBar: AppBar(title: const Text('Detalj vozila'),
        leading: IconButton(tooltip: 'Katalog', icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/cars'))),
        body: LoadView(state: state, child: listing == null || !isPublic(listing)
          ? const Center(child: Text('Oglas nije dostupan'))
          : ListView(padding: const EdgeInsets.all(24), children: [
            AspectRatio(aspectRatio: 16 / 10, child: CarPhoto(listing: listing)),
            const SizedBox(height: 16),
            Text(listing.title, style: Theme.of(context).textTheme.headlineMedium),
            Text('${listing.priceEur} € · ${statusLabel(listing.status)}',
              style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _detail('Marka', listing.specs.brand),
            _detail('Model', listing.specs.model),
            _detail('Godište', listing.specs.year == 0 ? '' : '${listing.specs.year}'),
            _detail('Kilometraža', listing.specs.mileageKm == 0 ? '' : '${listing.specs.mileageKm} km'),
            _detail('Karoserija', listing.specs.bodyType),
            _detail('Gorivo', listing.specs.fuel),
            _detail('Pogon', listing.specs.drive),
            _detail('Menjač', listing.specs.transmission),
            _detail('Brzine', listing.specs.gears),
            _detail('Vrata', listing.specs.doors),
            _detail('Boja', listing.specs.color),
            if (listing.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(listing.description),
            ],
            const SizedBox(height: 16),
            for (final action in allowedActions(listing, bloc.role, bloc.userId))
              FilledButton(onPressed: state.saving ? null : () async {
                if (action == ListingAction.cancelReservation) {
                  final confirmed = await confirmRemoval(context, 'Otkazati rezervaciju?',
                    'Otkazati rezervaciju za ${listing.title}?');
                  if (!confirmed || !context.mounted) return;
                }
                bloc.add(ListingActionRequested(listing.id, action));
              }, child: Text(actionLabel(action))),
            OutlinedButton(onPressed: () async {
              final saved = state.favorites.contains(listing.id);
              if (saved) {
                final confirmed = await confirmRemoval(context, 'Ukloniti favorit?',
                  'Ukloniti ${listing.title} iz favorita?');
                if (!confirmed || !context.mounted) return;
              }
              bloc.add(FavoriteSet(listing.id, !saved));
            }, child: Text(state.favorites.contains(listing.id) ? 'Ukloni favorit' : 'Sačuvaj favorit')),
            if (state.favorites.contains(listing.id))
              TextButton.icon(onPressed: () => context.push('/cars/${listing.id.value}/chat'),
                icon: const Icon(Icons.chat_bubble_outline), label: const Text('Demo chat')),
            if (state.saving) const LinearProgressIndicator(),
          ])));
    });
}

Widget _detail(String label, String value) => value.isEmpty ? const SizedBox.shrink()
  : Padding(padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 120, child: Text(label)),
        Expanded(child: Text(value)),
      ]));
