import 'package:dartz/dartz.dart';
import 'package:yapper/core/error/failures.dart';
import '../../domain/entities/user_summary.dart';
import '../../domain/repository/user_repository.dart';
import '../datasource/user_remote_data_source.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remote;
  UserRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, List<UserSummary>>> getRecentUsers(
      {int limit = 12}) async {
    try {
      final list = await remote.getRecentUsersOnce(limit: limit);
      return Right(list);
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}
