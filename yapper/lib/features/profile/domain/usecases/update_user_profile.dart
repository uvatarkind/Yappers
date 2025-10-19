import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/profile_entity.dart';
import '../repository/profile_repository.dart';

class UpdateUserProfile {
  final ProfileRepository repository;

  UpdateUserProfile(this.repository);

  Future<Either<Failure, void>> call(UserProfile user) {
    return repository.updateUserProfile(user);
  }
}
