// lib/core/error/failure.dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure({required this.message});

  @override
  List<Object> get props => [message];
}

// General failures from server/remote source
class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

// Can add other types later, like CacheFailure for local data