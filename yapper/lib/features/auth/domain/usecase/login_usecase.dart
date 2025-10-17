import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../repository/auth_repository.dart';

class LoginUsecase {
  final AuthRepository repository;

  LoginUsecase(this.repository);

  Future<Either<Failure, UserEntity>> call(
      {required String email, required String password}) async {
    return await repository.signInWithEmailAndPassword(email, password);
  }
}
