import 'listing.dart';
import 'result.dart';

Result<int> validatePrice(int? value) => value != null && value > 0
    ? Success(value) : const Failure(InvalidPrice());

Result<int> validatePositiveNumber(int? value) => value != null && value > 0
    ? Success(value) : const Failure(InvalidNumber());

Result<int> validateListingInput({required String title, required int? priceEur,
    CarSpecs specs = const CarSpecs()}) {
  if (title.trim().isEmpty) return const Failure(EmptyTitle());
  if (specs.year < 0 || specs.mileageKm < 0) return const Failure(InvalidNumber());
  return validatePrice(priceEur);
}

bool canTransition(ListingStatus from, ListingStatus to) => switch ((from, to)) {
  (Draft(), Active()) || (Active(), Reserved()) || (Reserved(), Active()) ||
  (Reserved(), Sold()) || (Active(), Withdrawn()) || (Withdrawn(), Active()) => true,
  _ => false,
};

CarListing? findListing(Iterable<CarListing> listings, ListingId id) {
  for (final listing in listings) {
    if (listing.id == id) return listing;
  }
  return null;
}

Result<CarListing> checkReservationAvailability(
    List<CarListing> listings, ListingId id) {
  final listing = findListing(listings, id);
  if (listing == null) return const Failure(ListingNotFound());
  return listing.status is Active ? Success(listing)
      : const Failure(ListingUnavailable());
}

ListingStatus _target(ListingAction action, UserId userId) => switch (action) {
  ListingAction.publish || ListingAction.cancelReservation => const Active(),
  ListingAction.reserve => Reserved(userId),
  ListingAction.sell => const Sold(),
  ListingAction.withdraw => const Withdrawn(),
};

bool _validSource(ListingStatus status, ListingAction action) => switch (action) {
  ListingAction.publish => status is Draft || status is Withdrawn,
  ListingAction.reserve || ListingAction.withdraw => status is Active,
  ListingAction.cancelReservation || ListingAction.sell => status is Reserved,
};

bool _authorized(CarListing listing, ListingAction action,
    UserRole role, UserId userId) => switch (action) {
  ListingAction.reserve => role == UserRole.customer,
  ListingAction.cancelReservation => role == UserRole.staff ||
      (listing.status is Reserved &&
        (listing.status as Reserved).reservedBy == userId),
  _ => role == UserRole.staff,
};

List<ListingAction> allowedActions(CarListing listing, UserRole role, UserId userId) =>
  ListingAction.values.where((action) => _authorized(listing, action, role, userId)
    && _validSource(listing.status, action)
    && canTransition(listing.status, _target(action, userId))).toList(growable: false);

Result<CarListing> applyListingAction(List<CarListing> listings, ListingId id,
    ListingAction action, UserRole role, UserId userId) {
  final listing = findListing(listings, id);
  if (listing == null) return const Failure(ListingNotFound());
  if (!_authorized(listing, action, role, userId)) {
    return const Failure(ForbiddenAction());
  }
  if (action == ListingAction.reserve) {
    final availability = checkReservationAvailability(listings, id);
    if (availability case Failure<CarListing>(:final error)) return Failure(error);
  }
  if (!_validSource(listing.status, action)) return const Failure(InvalidTransition());
  final target = _target(action, userId);
  if (!canTransition(listing.status, target)) return const Failure(InvalidTransition());
  return Success(listing.copyWith(status: target));
}

bool canEditListing(CarListing listing, UserRole role) =>
    role == UserRole.staff && listing.status is! Sold;
