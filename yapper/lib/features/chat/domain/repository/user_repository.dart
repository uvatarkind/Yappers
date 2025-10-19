import 'package:dartz/dartz.dart';
import 'package:yapper/core/error/failures.dart';
import '../entities/user_summary.dart';

abstract class UserRepository {
  Future<Either<Failure, List<UserSummary>>> getRecentUsers({int limit});
}
