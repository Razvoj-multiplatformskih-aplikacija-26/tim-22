import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:automatch_mobile/data/memory_listings_repository.dart';

void main() {
  test('arming during a request affects the following request', () async {
    final repository = MemoryListingsRepository(delay: Duration.zero);
    final pending = repository.getAll();
    repository.failNextRequest();
    expect(await pending, hasLength(12));
    await expectLater(repository.getAll(), throwsA(isA<RepositoryException>()));
    expect(await repository.getAll(), hasLength(12));
  });
  test('12 records, 10 public, five states and independent instances', () async {
    final first = MemoryListingsRepository(delay: Duration.zero);
    final second = MemoryListingsRepository(delay: Duration.zero);
    final seed = await first.getAll();
    expect(seed, hasLength(12));
    expect(publicListings(seed), hasLength(10));
    expect(seed.map((l) => l.status.runtimeType).toSet(), hasLength(5));
    expect(() => seed.clear(), throwsUnsupportedError);
    await first.update(seed.first.copyWith(status: const Withdrawn()));
    expect((await second.getAll()).first.status, const Active());
    final a = await first.create(title: 'A', priceEur: 1, description: '');
    final b = await first.create(title: 'B', priceEur: 1, description: '');
    expect(a.id, isNot(b.id));
    expect(a.status, const Draft());
  });
  test('each failed request is consumed once and never mutates data', () async {
    final repository = MemoryListingsRepository(delay: Duration.zero);
    final before = await repository.getAll();
    repository.failNextRequest();
    await expectLater(repository.getAll(), throwsA(isA<RepositoryException>()));
    expect(await repository.getAll(), before);
    repository.failNextRequest();
    await expectLater(repository.create(title: 'X', priceEur: 1, description: ''), throwsA(isA<RepositoryException>()));
    expect(await repository.getAll(), before);
    repository.failNextRequest();
    await expectLater(repository.update(before.first.copyWith(status: const Sold())), throwsA(isA<RepositoryException>()));
    expect(await repository.getAll(), before);
    await expectLater(repository.update(before.first.copyWith(title: 'Updated')), completes);
    const missing = CarListing(id: ListingId('missing'), title: 'Missing', priceEur: 1, description: '');
    await expectLater(repository.update(missing), throwsA(isA<RepositoryException>()));
    expect(await repository.getAll(), hasLength(12));
  });
}
