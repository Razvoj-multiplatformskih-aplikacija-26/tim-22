import 'dart:async';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

const id = ListingId('one');
const car = CarListing(id: id, title: 'Toyota', priceEur: 100,
  description: '', status: Active());

class TestRepository implements ListingsRepository {
  List<CarListing> listings = [car];
  bool fail = false;
  int writes = 0;
  Completer<void>? gate;
  @override
  Future<List<CarListing>> getAll() async {
    if (fail) { fail = false; throw const RepositoryException(); }
    return List.of(listings);
  }
  @override
  Future<CarListing> update(CarListing listing) async {
    writes++;
    await gate?.future;
    if (fail) { fail = false; throw const RepositoryException(); }
    listings = [listing];
    return listing;
  }
  @override
  Future<CarListing> create({required String title, required int priceEur,
      required String description, CarSpecs specs = const CarSpecs()}) async {
    writes++;
    return CarListing(id: const ListingId('new'), title: title,
      priceEur: priceEur, description: description, specs: specs);
  }
}

Future<void> dispatch(ListingsBloc bloc, ListingsEvent event,
    bool Function(ListingsState) done) async {
  final completed = bloc.stream.firstWhere(done);
  bloc.add(event);
  await completed.timeout(const Duration(seconds: 3));
}

void main() {
  late TestRepository repository;
  late ListingsBloc bloc;
  setUp(() {
    repository = TestRepository();
    bloc = ListingsBloc(repository: repository, role: UserRole.customer,
      userId: const UserId('user-1'));
  });
  tearDown(() async { await bloc.close(); });

  test('filters are immutable, validate budget and preserve saved selections', () async {
    await dispatch(bloc, const LoadRequested(), (s) => s.status == LoadStatus.ready);
    final old = bloc.state;
    const filters = ListingFilters(maxPrice: 100, specs: CarSpecs(color: 'Crvena', drive: 'Prednji'));
    await dispatch(bloc, const FiltersChanged(filters), (s) => s.filters == filters);
    expect(old.filters, const ListingFilters());
    await dispatch(bloc, const FiltersChanged(ListingFilters(maxPrice: 0)),
      (s) => s.domainError is InvalidPrice);
    expect(bloc.state.filters, filters);
    repository.fail = true;
    await dispatch(bloc, const LoadRequested(), (s) => s.status == LoadStatus.failure);
    expect(bloc.state.filters, filters);
    await dispatch(bloc, const FiltersChanged(ListingFilters()), (s) => s.filters.isEmpty);
    expect(bloc.state.domainError, isNull);
  });

  test('loading failure, retry and empty ready data', () async {
    repository.fail = true;
    final statuses = <LoadStatus>[];
    final subscription = bloc.stream.listen((s) => statuses.add(s.status));
    await dispatch(bloc, const LoadRequested(), (s) => s.status == LoadStatus.failure);
    repository.listings = [];
    await dispatch(bloc, const LoadRequested(), (s) => s.status == LoadStatus.ready);
    expect(statuses, containsAllInOrder([LoadStatus.loading, LoadStatus.failure, LoadStatus.loading, LoadStatus.ready]));
    expect(bloc.state.listings, isEmpty);
    expect(bloc.state.repositoryError, isFalse);
    await subscription.cancel();
  });

  test('write is visible only after success; rapid second reservation is rejected', () async {
    await dispatch(bloc, const LoadRequested(), (s) => s.status == LoadStatus.ready);
    final previous = bloc.state;
    repository.gate = Completer<void>();
    final saving = bloc.stream.firstWhere((s) => s.saving);
    bloc.add(const ListingActionRequested(id, ListingAction.reserve));
    bloc.add(const ListingActionRequested(id, ListingAction.reserve));
    await saving;
    expect(bloc.state.listings.single.status, const Active());
    final rejected = bloc.stream.firstWhere((s) => s.domainError is ListingUnavailable);
    repository.gate!.complete();
    await rejected.timeout(const Duration(seconds: 3));
    expect(repository.writes, 1);
    expect(bloc.state.listings.single.status, const Reserved(UserId('user-1')));
    expect(previous.listings.single.status, const Active());
    expect(() => previous.listings.clear(), throwsUnsupportedError);
  });

  test('failed write preserves data; retry succeeds and clears error', () async {
    await dispatch(bloc, const LoadRequested(), (s) => s.status == LoadStatus.ready);
    repository.fail = true;
    await dispatch(bloc, const ListingActionRequested(id, ListingAction.reserve), (s) => s.repositoryError);
    expect(bloc.state.listings.single, car);
    expect(repository.listings.single, car);
    await dispatch(bloc, const ListingActionRequested(id, ListingAction.reserve),
      (s) => !s.saving && s.listings.single.status is Reserved);
    expect(bloc.state.repositoryError, isFalse);
  });

  test('favorites are idempotent and independent of reservations and refresh failures', () async {
    await dispatch(bloc, const LoadRequested(), (s) => s.status == LoadStatus.ready);
    final old = bloc.state;
    bloc.add(const FavoriteSet(id, true));
    bloc.add(const FavoriteSet(id, true));
    await dispatch(bloc, const FiltersChanged(ListingFilters(maxPrice: 100)), (s) => s.filters.maxPrice == 100);
    expect(bloc.state.favorites, {id});
    expect(old.favorites, isEmpty);
    await dispatch(bloc, const ListingActionRequested(id, ListingAction.reserve),
      (s) => !s.saving && s.listings.single.status is Reserved);
    await dispatch(bloc, const FavoriteSet(id, false), (s) => s.favorites.isEmpty);
    expect(bloc.state.listings.single.status, isA<Reserved>());
    repository.fail = true;
    await dispatch(bloc, const LoadRequested(), (s) => s.status == LoadStatus.failure);
    expect(bloc.state.filters.maxPrice, 100);
    expect(bloc.state.listings.single.status, isA<Reserved>());
  });

  test('save validates role and input before calling the port', () async {
    await dispatch(bloc, const ListingSaved(title: 'X', priceEur: 1, description: ''),
      (s) => s.domainError is ForbiddenAction);
    final staff = ListingsBloc(repository: repository, role: UserRole.staff, userId: const UserId('staff'));
    try {
      await dispatch(staff, const LoadRequested(), (s) => s.status == LoadStatus.ready);
      for (final listingId in [null, id]) {
        await dispatch(staff, ListingSaved(id: listingId, title: 'X', priceEur: 0, description: ''),
          (s) => s.domainError is InvalidPrice);
        await dispatch(staff, FiltersChanged(ListingFilters(maxPrice: listingId == null ? 1 : 2)),
          (s) => s.domainError == null);
      }
      expect(repository.writes, 0);
      await dispatch(staff, const ListingSaved(title: 'New', priceEur: 1, description: ''),
        (s) => s.saveRevision == 1);
      expect(staff.state.listings.last.status, const Draft());
      await dispatch(staff, const ListingSaved(id: id, title: 'Edited', priceEur: 2, description: ''),
        (s) => s.saveRevision == 2);
      expect(findListing(staff.state.listings, id)!.title, 'Edited');
      await dispatch(staff, const ListingSaved(id: id, title: 'Edited', priceEur: 2,
        description: '', specs: CarSpecs(brand: 'Toyota', model: 'Yaris',
          year: 2019, mileageKm: 85000, fuel: 'Benzin')),
        (s) => s.saveRevision == 3);
      expect(findListing(staff.state.listings, id)!.specs,
        const CarSpecs(brand: 'Toyota', model: 'Yaris', year: 2019,
          mileageKm: 85000, fuel: 'Benzin'));
    } finally { await staff.close(); }
  });
}
