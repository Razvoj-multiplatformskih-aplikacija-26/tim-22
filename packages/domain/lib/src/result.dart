import 'package:equatable/equatable.dart';

sealed class Result<T> {
  const Result();
}
final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}
final class Failure<T> extends Result<T> {
  const Failure(this.error);
  final DomainError error;
}

sealed class DomainError extends Equatable {
  const DomainError();
  @override
  List<Object?> get props => [];
}
final class InvalidPrice extends DomainError { const InvalidPrice(); }
final class InvalidNumber extends DomainError { const InvalidNumber(); }
final class EmptyTitle extends DomainError { const EmptyTitle(); }
final class ListingNotFound extends DomainError { const ListingNotFound(); }
final class ListingUnavailable extends DomainError { const ListingUnavailable(); }
final class ForbiddenAction extends DomainError { const ForbiddenAction(); }
final class InvalidTransition extends DomainError { const InvalidTransition(); }
