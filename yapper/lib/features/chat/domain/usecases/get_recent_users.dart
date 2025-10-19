import 'package:dartz/dartz.dart';
import 'package:yapper/core/error/failures.dart';
import '../entities/user_summary.dart';
import '../repository/user_repository.dart';

class GetRecentUsersUseCase {
  final UserRepository repository;
  const GetRecentUsersUseCase(this.repository);

  Future<Either<Failure, List<UserSummary>>> call({int limit = 12}) {
    return repository.getRecentUsers(limit: limit);
  }
}
