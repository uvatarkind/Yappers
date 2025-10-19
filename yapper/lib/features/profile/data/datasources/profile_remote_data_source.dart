import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yapper/features/storage/supabase_storage_service.dart';
import '../models/user_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getUserProfile(String uid);
  Future<void> updateUserProfile(UserProfileModel user);
  Future<String> uploadProfilePicture(File image, String uid);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseFirestore firestore;
  final SupabaseStorageService storage;

  ProfileRemoteDataSourceImpl({required this.firestore, required this.storage});

  @override
  Future<UserProfileModel> getUserProfile(String uid) async {
    final docSnapshot = await firestore.collection('users').doc(uid).get();
    if (docSnapshot.exists) {
      return UserProfileModel.fromFirestore(docSnapshot);
    } else {
      throw Exception('User not found');
    }
  }

  @override
  Future<void> updateUserProfile(UserProfileModel user) async {
    await firestore
        .collection('users')
        .doc(user.uid)
        .update(user.toFirestore());
  }

  @override
  Future<String> uploadProfilePicture(File image, String uid) async {
    final path = 'profile_pictures/$uid.jpg';
    await storage.uploadFile(
        path: path, file: image, contentType: 'image/jpeg');
    return storage.getPublicUrl(path);
  }
}
