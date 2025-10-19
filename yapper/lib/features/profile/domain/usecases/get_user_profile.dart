import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/profile_entity.dart';
import '../repository/profile_repository.dart';

class GetUserProfile {
  final ProfileRepository repository;

  GetUserProfile(this.repository);

  Future<Either<Failure, UserProfile>> call(String uid) {
    return repository.getUserProfile(uid);
  }
}
