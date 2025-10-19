import 'dart:io';

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserProfile>> getUserProfile(String uid);
  Future<Either<Failure, void>> updateUserProfile(UserProfile user);
  Future<Either<Failure, String>> uploadProfilePicture(File image, String uid);
}
