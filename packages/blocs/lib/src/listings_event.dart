import 'package:domain/domain.dart';

sealed class ListingsEvent { const ListingsEvent(); }
final class LoadRequested extends ListingsEvent { const LoadRequested(); }
final class ListingActionRequested extends ListingsEvent {
  const ListingActionRequested(this.id, this.action);
  final ListingId id;
  final ListingAction action;
}
final class ListingSaved extends ListingsEvent {
  const ListingSaved({this.id, required this.title, required this.priceEur,
    required this.description, this.specs = const CarSpecs()});
  final ListingId? id;
  final String title;
  final int? priceEur;
  final String description;
  final CarSpecs specs;
}
final class FavoriteSet extends ListingsEvent {
  const FavoriteSet(this.id, this.saved);
  final ListingId id;
  final bool saved;
}
final class FiltersChanged extends ListingsEvent {
  const FiltersChanged(this.filters);
  final ListingFilters filters;
}
