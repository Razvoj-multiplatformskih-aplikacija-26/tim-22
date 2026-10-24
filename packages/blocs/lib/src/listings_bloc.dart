import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'listings_event.dart';
import 'listings_repository.dart';
import 'listings_state.dart';

final class ListingsBloc extends Bloc<ListingsEvent, ListingsState> {
  ListingsBloc({required this.repository, required this.role, required this.userId})
    : super(ListingsState()) {
    on<ListingsEvent>(_handle,
      transformer: (events, mapper) => events.asyncExpand(mapper));
  }
  final ListingsRepository repository;
  final UserRole role;
  final UserId userId;

  Future<void> _handle(ListingsEvent event, Emitter<ListingsState> emit) async {
    switch (event) {
      case LoadRequested():
        emit(state.copyWith(status: LoadStatus.loading));
        try {
          final listings = await repository.getAll();
          emit(state.copyWith(status: LoadStatus.ready, listings: listings));
        } on RepositoryException {
          emit(state.copyWith(status: LoadStatus.failure, repositoryError: true));
        }
      case ListingActionRequested(:final id, :final action):
        final result = applyListingAction(state.listings, id, action, role, userId);
        switch (result) {
          case Failure<CarListing>(:final error):
            emit(state.copyWith(domainError: error));
          case Success<CarListing>(:final value):
            await _persist(emit, () => repository.update(value));
        }
      case ListingSaved(:final id, :final title, :final priceEur, :final description, :final specs):
        final existing = id == null ? null : findListing(state.listings, id);
        if (role != UserRole.staff ||
            (existing != null && !canEditListing(existing, role))) {
          emit(state.copyWith(domainError: const ForbiddenAction()));
          return;
        }
        if (id != null && existing == null) {
          emit(state.copyWith(domainError: const ListingNotFound()));
          return;
        }
        final validation = validateListingInput(title: title, priceEur: priceEur, specs: specs);
        switch (validation) {
          case Failure<int>(:final error):
            emit(state.copyWith(domainError: error));
          case Success<int>(:final value):
            await _persist(emit, () => existing == null
              ? repository.create(title: title.trim(), priceEur: value,
                  description: description.trim(), specs: specs)
              : repository.update(existing.copyWith(title: title.trim(),
                  priceEur: value, description: description.trim(), specs: specs)), formSave: true);
        }
      case FavoriteSet(:final id, :final saved):
        final listing = findListing(state.listings, id);
        if (listing == null || !isPublic(listing)) {
          emit(state.copyWith(domainError: const ListingNotFound()));
          return;
        }
        final favorites = {...state.favorites};
        if (saved) { favorites.add(id); } else { favorites.remove(id); }
        emit(state.copyWith(favorites: favorites));
      case FiltersChanged(:final filters):
        final maxPrice = filters.maxPrice;
        if (maxPrice != null) {
          final result = validatePrice(maxPrice);
          if (result case Failure<int>(:final error)) {
            emit(state.copyWith(domainError: error));
            return;
          }
        }
        for (final number in [filters.maxMileageKm, filters.minYear]) {
          if (number != null) {
            final validation = validatePositiveNumber(number);
            if (validation case Failure<int>(:final error)) {
              emit(state.copyWith(domainError: error));
              return;
            }
          }
        }
        emit(state.copyWith(filters: filters));
    }
  }

  Future<void> _persist(Emitter<ListingsState> emit,
      Future<CarListing> Function() write, {bool formSave = false}) async {
    emit(state.copyWith(saving: true));
    try {
      final saved = await write();
      final listings = [...state.listings];
      final index = listings.indexWhere((l) => l.id == saved.id);
      if (index < 0) { listings.add(saved); } else { listings[index] = saved; }
      emit(state.copyWith(listings: listings, saving: false,
        savedId: formSave ? saved.id : null,
        saveRevision: state.saveRevision + (formSave ? 1 : 0)));
    } on RepositoryException {
      emit(state.copyWith(saving: false, repositoryError: true));
    }
  }
}
