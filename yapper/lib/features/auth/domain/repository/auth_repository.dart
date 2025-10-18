import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import 'package:equatable/equatable.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword(
      String email, String password);
  Future<Either<Failure, UserEntity>> signUpWithEmailAndPassword(
      String email, String password, String name);
  Future<Either<Failure, void>> logOut();
}

// A generic Failure class for error handling
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}
