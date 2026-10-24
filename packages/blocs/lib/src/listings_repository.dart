import 'package:domain/domain.dart';

abstract interface class ListingsRepository {
  Future<List<CarListing>> getAll();
  Future<CarListing> create({required String title, required int priceEur,
    required String description, CarSpecs specs = const CarSpecs()});
  Future<CarListing> update(CarListing listing);
}

final class RepositoryException implements Exception {
  const RepositoryException();
}
