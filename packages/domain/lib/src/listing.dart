import 'package:equatable/equatable.dart';

extension type const ListingId(String value) {}
extension type const UserId(String value) {}

enum UserRole { customer, staff }
enum ListingAction { publish, reserve, cancelReservation, sell, withdraw }

sealed class ListingStatus extends Equatable {
  const ListingStatus();
  @override
  List<Object?> get props => [];
}

final class Draft extends ListingStatus {
  const Draft();
}
final class Active extends ListingStatus {
  const Active();
}
final class Reserved extends ListingStatus {
  const Reserved(this.reservedBy);
  final UserId reservedBy;
  @override
  List<Object?> get props => [reservedBy.value];
}
final class Sold extends ListingStatus {
  const Sold();
}
final class Withdrawn extends ListingStatus {
  const Withdrawn();
}

final class CarSpecs extends Equatable {
  const CarSpecs({this.brand = '', this.model = '', this.year = 0,
    this.mileageKm = 0, this.bodyType = '', this.drive = '',
    this.doors = '', this.color = '', this.transmission = '',
    this.gears = '', this.fuel = ''});
  final String brand, model, bodyType, drive, doors, color, transmission, gears, fuel;
  final int year, mileageKm;

  @override
  List<Object?> get props => [brand, model, year, mileageKm,
    bodyType, drive, doors, color, transmission, gears, fuel];
}

final class CarListing extends Equatable {
  const CarListing({required this.id, required this.title,
    required this.priceEur, required this.description, this.status = const Draft(),
    this.specs = const CarSpecs(), this.imageAsset = 'assets/cars/default.jpg'});
  final ListingId id;
  final String title;
  final int priceEur;
  final String description;
  final ListingStatus status;
  final CarSpecs specs;
  final String imageAsset;

  CarListing copyWith({String? title, int? priceEur, String? description,
    ListingStatus? status, CarSpecs? specs}) => CarListing(id: id, title: title ?? this.title,
      priceEur: priceEur ?? this.priceEur,
      description: description ?? this.description, status: status ?? this.status,
      specs: specs ?? this.specs, imageAsset: imageAsset);

  @override
  List<Object?> get props => [id.value, title, priceEur, description, status, specs, imageAsset];
}
