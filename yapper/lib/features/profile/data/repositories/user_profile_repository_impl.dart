import 'dart:io';

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repository/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';
import '../models/user_profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserProfile>> getUserProfile(String uid) async {
    try {
      final userModel = await remoteDataSource.getUserProfile(uid);
      return Right(userModel);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateUserProfile(UserProfile user) async {
    try {
      final userModel = UserProfileModel(
        uid: user.uid,
        name: user.name,
        bio: user.bio,
        phoneNumber: user.phoneNumber,
        email: user.email,
        profilePictureUrl: user.profilePictureUrl,
        emotion: user.emotion,
      );
      await remoteDataSource.updateUserProfile(userModel);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, String>> uploadProfilePicture(
      File image, String uid) async {
    try {
      final imageUrl = await remoteDataSource.uploadProfilePicture(image, uid);
      return Right(imageUrl);
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}
