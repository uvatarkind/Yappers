import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../repository/auth_repository.dart';

class SignupUsecase {
  final AuthRepository repository;

  SignupUsecase(this.repository);

  Future<Either<Failure, UserEntity>> call(
      {required String email,
      required String password,
      required String name}) async {
    return await repository.signUpWithEmailAndPassword(email, password, name);
  }
}
