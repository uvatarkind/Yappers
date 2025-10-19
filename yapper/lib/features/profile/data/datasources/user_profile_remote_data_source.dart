import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:yapper/features/profile/data/models/user_profile_model.dart';
import 'package:yapper/features/storage/supabase_storage_service.dart';

abstract class UserProfileRemoteDataSource {
  Future<UserProfileModel> getUserProfile(String uid);
  Future<void> updateUserProfile(UserProfileModel userProfile);
  Future<String> uploadProfilePicture(File image, String uid);
}

class UserProfileRemoteDataSourceImpl implements UserProfileRemoteDataSource {
  final FirebaseFirestore firestore;
  final SupabaseStorageService storage;

  UserProfileRemoteDataSourceImpl(
      {required this.firestore, required this.storage});

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
  Future<void> updateUserProfile(UserProfileModel userProfile) async {
    await firestore
        .collection('users')
        .doc(userProfile.uid)
        .set(userProfile.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<String> uploadProfilePicture(File image, String uid) async {
    final path = 'profile_pictures/$uid.jpg';
    await storage.uploadFile(
        path: path, file: image, contentType: 'image/jpeg');
    return storage.getPublicUrl(path);
  }
}
