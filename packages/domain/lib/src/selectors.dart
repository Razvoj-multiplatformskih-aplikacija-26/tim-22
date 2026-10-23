import 'listing.dart';
import 'listing_filters.dart';

bool isPublic(CarListing listing) => switch (listing.status) {
  Active() || Reserved() || Sold() => true,
  _ => false,
};

List<CarListing> publicListings(Iterable<CarListing> listings) =>
    listings.where(isPublic).toList(growable: false);
List<CarListing> favoriteListings(Iterable<CarListing> listings, Set<ListingId> ids) =>
    listings.where((l) => isPublic(l) && ids.contains(l.id)).toList(growable: false);
List<CarListing> myReservations(Iterable<CarListing> listings, UserId userId) =>
    listings.where((l) => l.status is Reserved &&
      (l.status as Reserved).reservedBy == userId).toList(growable: false);
List<CarListing> filterListings(Iterable<CarListing> listings,
    {String query = '', ListingFilters filters = const ListingFilters(), bool reservedOnly = false}) =>
    listings.where((l) => l.title.toLowerCase().contains(query.trim().toLowerCase())
      && filters.matches(l)
      && (!reservedOnly || l.status is Reserved)).toList(growable: false);
