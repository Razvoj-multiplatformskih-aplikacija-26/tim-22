import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

enum LoadStatus { loading, ready, failure }

final class ListingsState extends Equatable {
  ListingsState({this.status = LoadStatus.loading, List<CarListing> listings = const [],
    Set<ListingId> favorites = const {}, this.filters = const ListingFilters(), this.saving = false,
    this.domainError, this.repositoryError = false, this.savedId, this.saveRevision = 0})
    : listings = List.unmodifiable(listings), favorites = Set.unmodifiable(favorites);
  final LoadStatus status;
  final List<CarListing> listings;
  final Set<ListingId> favorites;
  final ListingFilters filters;
  final bool saving;
  final DomainError? domainError;
  final bool repositoryError;
  final ListingId? savedId;
  final int saveRevision;

  ListingsState copyWith({LoadStatus? status, List<CarListing>? listings,
    Set<ListingId>? favorites, ListingFilters? filters,
    bool? saving, DomainError? domainError, bool repositoryError = false,
    ListingId? savedId, int? saveRevision}) => ListingsState(
      status: status ?? this.status, listings: listings ?? this.listings,
      favorites: favorites ?? this.favorites,
      filters: filters ?? this.filters,
      saving: saving ?? this.saving, domainError: domainError,
      repositoryError: repositoryError, savedId: savedId ?? this.savedId,
      saveRevision: saveRevision ?? this.saveRevision);

  @override
  List<Object?> get props => [status, listings, favorites, filters, saving,
    domainError, repositoryError, savedId?.value, saveRevision];
}
