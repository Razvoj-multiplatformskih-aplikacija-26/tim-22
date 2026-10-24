import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'demo_listings.dart';

final class MemoryListingsRepository implements ListingsRepository {
  MemoryListingsRepository({this.delay = const Duration(milliseconds: 400)})
      : _listings = demoListings();
  final Duration delay;
  final List<CarListing> _listings;
  bool _failNext = false;
  int _nextId = 1;

  void failNextRequest() => _failNext = true;
  Future<void> _wait() async {
    final fail = _failNext;
    _failNext = false;
    await Future<void>.delayed(delay);
    if (fail) throw const RepositoryException();
  }

  @override
  Future<List<CarListing>> getAll() async {
    await _wait();
    return List.unmodifiable(_listings);
  }

  @override
  Future<CarListing> create({required String title, required int priceEur,
      required String description, CarSpecs specs = const CarSpecs()}) async {
    await _wait();
    final listing = CarListing(id: ListingId('new-${_nextId++}'), title: title,
      priceEur: priceEur, description: description, specs: specs);
    _listings.add(listing);
    return listing;
  }

  @override
  Future<CarListing> update(CarListing listing) async {
    await _wait();
    final index = _listings.indexWhere((l) => l.id == listing.id);
    if (index < 0) throw const RepositoryException();
    _listings[index] = listing;
    return listing;
  }
}
