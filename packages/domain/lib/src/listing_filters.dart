import 'package:equatable/equatable.dart';
import 'listing.dart';

final class ListingFilters extends Equatable {
  const ListingFilters({this.maxPrice, this.maxMileageKm, this.minYear,
    this.specs = const CarSpecs()});
  final int? maxPrice, maxMileageKm, minYear;
  final CarSpecs specs;
  bool get isEmpty => this == const ListingFilters();

  bool matches(CarListing listing) {
    final car = listing.specs;
    return (maxPrice == null || listing.priceEur <= maxPrice!)
      && (maxMileageKm == null || (car.mileageKm > 0 && car.mileageKm <= maxMileageKm!))
      && (minYear == null || car.year >= minYear!)
      && (specs.brand.isEmpty || car.brand == specs.brand)
      && (specs.model.isEmpty || car.model == specs.model)
      && (specs.bodyType.isEmpty || car.bodyType == specs.bodyType)
      && (specs.drive.isEmpty || car.drive == specs.drive)
      && (specs.doors.isEmpty || car.doors == specs.doors)
      && (specs.color.isEmpty || car.color == specs.color)
      && (specs.transmission.isEmpty || car.transmission == specs.transmission)
      && (specs.gears.isEmpty || car.gears == specs.gears)
      && (specs.fuel.isEmpty || car.fuel == specs.fuel);
  }

  @override
  List<Object?> get props => [maxPrice, maxMileageKm, minYear, specs];
}
