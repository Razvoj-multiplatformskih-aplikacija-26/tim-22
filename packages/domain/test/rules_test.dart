import 'package:domain/domain.dart';
import 'package:test/test.dart';

const user = UserId('user-1');
const other = UserId('user-2');
const id = ListingId('car-1');
CarListing car(ListingStatus status) => CarListing(id: id, title: 'Toyota',
  priceEur: 100, description: '', status: status);

void main() {
  test('all car filters combine with AND and unknown specs do not match', () {
    const red = CarListing(id: ListingId('red'), title: 'Yaris', priceEur: 7900,
      imageAsset: 'assets/cars/car-1.jpg',
      description: '', specs: CarSpecs(brand: 'Toyota', model: 'Yaris', bodyType: 'Hečbek',
        drive: 'Prednji', doors: '3', color: 'Crvena', transmission: 'Manuelni',
        gears: '5', fuel: 'Benzin'));
    const blue = CarListing(id: ListingId('blue'), title: 'Clio', priceEur: 6500,
      description: '', specs: CarSpecs(brand: 'Renault', model: 'Clio', bodyType: 'Hečbek',
        drive: 'Prednji', doors: '5', color: 'Plava', transmission: 'Automatski',
        gears: '6', fuel: 'Dizel'));
    final listings = [red, blue, car(const Active())];
    const specs = [
      CarSpecs(model: 'Yaris'), CarSpecs(bodyType: 'Hečbek'),
      CarSpecs(drive: 'Prednji'), CarSpecs(doors: '3'), CarSpecs(color: 'Crvena'),
      CarSpecs(transmission: 'Manuelni'), CarSpecs(gears: '5'), CarSpecs(fuel: 'Benzin'),
    ];
    for (final spec in specs) {
      final matches = filterListings(listings, filters: ListingFilters(specs: spec));
      expect(matches, contains(red));
      expect(matches, isNot(contains(listings.last)));
    }
    expect(filterListings(listings, filters: const ListingFilters(maxPrice: 7900,
      specs: CarSpecs(bodyType: 'Hečbek', color: 'Crvena', transmission: 'Manuelni'))), [red]);
    expect(filterListings(listings, filters: const ListingFilters(
      specs: CarSpecs(color: 'Crvena', transmission: 'Automatski'))), isEmpty);
    expect(filterListings(listings, filters: const ListingFilters(maxPrice: 7899,
      specs: CarSpecs(model: 'Yaris'))), isEmpty);
    expect(filterListings(listings), listings);
    expect(red.copyWith(title: 'Edited', status: const Active()).specs, red.specs);
    expect(red.copyWith(status: const Reserved(user)).imageAsset, red.imageAsset);
  });

  test('positive integer price and nonempty title', () {
    expect(validatePrice(1), isA<Success<int>>());
    for (final value in [null, 0, -1]) {
      expect(validatePrice(value), isA<Failure<int>>().having((r) => r.error, 'error', isA<InvalidPrice>()));
    }
    expect(validateListingInput(title: '  ', priceEur: 1),
      isA<Failure<int>>().having((r) => r.error, 'error', isA<EmptyTitle>()));
  });

  test('brand, year and mileage filters use structured fields', () {
    const car = CarListing(id: ListingId('hyundai'), title: 'i30', priceEur: 14400,
      description: '', specs: CarSpecs(brand: 'Hyundai', model: 'i30',
        year: 2021, mileageKm: 45000));
    expect(filterListings([car], filters: const ListingFilters(minYear: 2021,
      maxMileageKm: 45000, specs: CarSpecs(brand: 'Hyundai'))), [car]);
    expect(filterListings([car], filters: const ListingFilters(maxMileageKm: 44999)), isEmpty);
    expect(filterListings([car], filters: const ListingFilters(minYear: 2022)), isEmpty);
    expect(filterListings([car], filters: const ListingFilters(
      specs: CarSpecs(brand: 'Toyota'))), isEmpty);
    expect(validatePositiveNumber(0), isA<Failure<int>>());
    expect(validateListingInput(title: 'Toyota', priceEur: 1,
      specs: const CarSpecs(mileageKm: -1)), isA<Failure<int>>());
  });

  test('all 25 status pairs follow the transition contract', () {
    const states = [Draft(), Active(), Reserved(user), Sold(), Withdrawn()];
    const allowed = {(0, 1), (1, 2), (2, 1), (2, 3), (1, 4), (4, 1)};
    for (var from = 0; from < states.length; from++) {
      for (var to = 0; to < states.length; to++) {
        expect(canTransition(states[from], states[to]), allowed.contains((from, to)),
          reason: '$from -> $to');
      }
    }
  });

  test('second customer cannot reserve an already reserved listing', () {
    final first = applyListingAction([car(const Active())], id,
      ListingAction.reserve, UserRole.customer, user) as Success<CarListing>;
    expect(first.value.status, const Reserved(user));
    expect(applyListingAction([first.value], id, ListingAction.reserve, UserRole.customer, other),
      isA<Failure<CarListing>>().having((r) => r.error, 'error', isA<ListingUnavailable>()));
    for (final status in [const Draft(), const Withdrawn(), const Sold(), const Reserved(other)]) {
      expect(checkReservationAvailability([car(status)], id), isA<Failure<CarListing>>());
    }
    expect(checkReservationAvailability([], id), isA<Failure<CarListing>>());
  });

  test('ownership, staff permissions and terminal status', () {
    final reserved = car(const Reserved(user));
    expect(allowedActions(reserved, UserRole.customer, user), [ListingAction.cancelReservation]);
    expect(allowedActions(reserved, UserRole.customer, other), isEmpty);
    expect(allowedActions(reserved, UserRole.staff, other),
      containsAll([ListingAction.cancelReservation, ListingAction.sell]));
    for (final action in [ListingAction.publish, ListingAction.sell, ListingAction.withdraw]) {
      expect(applyListingAction([reserved], id, action, UserRole.customer, user), isA<Failure<CarListing>>());
    }
    expect(canEditListing(reserved, UserRole.customer), isFalse);
    expect(canEditListing(car(const Sold()), UserRole.staff), isFalse);
    expect(allowedActions(car(const Sold()), UserRole.staff, user), isEmpty);
  });

  test('staff actions cannot borrow another action’s transition to Active', () {
    expect(allowedActions(car(const Draft()), UserRole.staff, user), [ListingAction.publish]);
    expect(allowedActions(car(const Withdrawn()), UserRole.staff, user), [ListingAction.publish]);
    expect(allowedActions(car(const Active()), UserRole.staff, user), [ListingAction.withdraw]);
    expect(allowedActions(car(const Reserved(user)), UserRole.staff, user),
      [ListingAction.cancelReservation, ListingAction.sell]);
    expect(applyListingAction([car(const Draft())], id, ListingAction.cancelReservation,
      UserRole.staff, user), isA<Failure<CarListing>>());
    expect(applyListingAction([car(const Reserved(user))], id, ListingAction.publish,
      UserRole.staff, user), isA<Failure<CarListing>>());
    expect((applyListingAction([car(const Draft())], id, ListingAction.publish,
      UserRole.staff, user) as Success<CarListing>).value.status, const Active());
    expect((applyListingAction([car(const Reserved(user))], id,
      ListingAction.cancelReservation, UserRole.staff, user) as Success<CarListing>)
      .value.status, const Active());
  });

  test('public visibility, ownership and inclusive budget', () {
    final listings = [car(const Active()),
      const CarListing(id: ListingId('draft'), title: 'Draft', priceEur: 50, description: ''),
      const CarListing(id: ListingId('hidden'), title: 'Hidden', priceEur: 50,
        description: '', status: Withdrawn()),
      const CarListing(id: ListingId('mine'), title: 'Mine', priceEur: 200,
        description: '', status: Reserved(user)),
      const CarListing(id: ListingId('other'), title: 'Other', priceEur: 200,
        description: '', status: Reserved(other)),
      const CarListing(id: ListingId('sold'), title: 'Sold', priceEur: 50,
        description: '', status: Sold()),
    ];
    expect(publicListings(listings), hasLength(4));
    expect(myReservations(listings, user).single.id, const ListingId('mine'));
    expect(filterListings(publicListings(listings), query: 'TOY', filters: const ListingFilters(maxPrice: 100)), [listings.first]);
    expect(favoriteListings(listings, {const ListingId('sold'), const ListingId('draft')}), [listings.last]);
    expect(filterListings(listings, reservedOnly: true), hasLength(2));
  });

  test('models and reservation owners compare by value', () {
    expect(car(const Active()), car(const Active()));
    expect(const Reserved(user), isNot(const Reserved(other)));
  });
}
