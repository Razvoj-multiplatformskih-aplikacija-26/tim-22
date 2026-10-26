import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../presentation.dart';

class ListingDetails extends StatelessWidget {
  const ListingDetails({super.key, required this.listing, required this.state});
  final CarListing listing;
  final ListingsState state;

  Future<void> act(BuildContext context, ListingAction action) async {
    if (action == ListingAction.sell || action == ListingAction.cancelReservation) {
      final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: Text(action == ListingAction.sell ? 'Potvrda prodaje' : 'Otkazati rezervaciju?'),
        content: Text(action == ListingAction.sell
          ? 'Prodaja je konačna. Označiti vozilo kao prodato?'
          : 'Otkazati rezervaciju za ${listing.title}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Potvrdi')),
        ]));
      if (confirmed != true || !context.mounted) return;
    }
    context.read<ListingsBloc>().add(ListingActionRequested(listing.id, action));
  }
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ListingsBloc>();
    return ListView(padding: const EdgeInsets.all(20), children: [
      AspectRatio(aspectRatio: 16 / 10, child: CarPhoto(listing: listing)),
      const SizedBox(height: 12),
      Text('Detalj · ${listing.id.value}', key: const ValueKey('selected-listing')),
      Text(listing.title, style: Theme.of(context).textTheme.headlineSmall),
      Text('${listing.priceEur} € · ${statusLabel(listing.status)}'),
      Text(specSummary(listing.specs)),
      const SizedBox(height: 12), Text(listing.description),
      if (listing.status case Reserved(:final reservedBy)) Text('Rezervisao: ${reservedBy.value}'),
      const SizedBox(height: 16),
      if (canEditListing(listing, bloc.role)) OutlinedButton(
        onPressed: state.saving ? null : () => context.push('/cars/${listing.id.value}/edit'),
        child: const Text('Izmeni')),
      for (final action in allowedActions(listing, bloc.role, bloc.userId))
        Padding(padding: const EdgeInsets.only(top: 8), child: FilledButton(
          onPressed: state.saving ? null : () => act(context, action), child: Text(actionLabel(action)))),
      if (state.saving) const LinearProgressIndicator(),
    ]);
  }
}
