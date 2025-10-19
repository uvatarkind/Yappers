import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:yapper/core/error/failures.dart';
import 'package:yapper/features/profile/domain/repository/profile_repository.dart';

class UploadProfilePicture {
  final ProfileRepository repository;

  UploadProfilePicture(this.repository);

  Future<Either<Failure, String>> call(File image, String uid) async {
    return await repository.uploadProfilePicture(image, uid);
  }
}
