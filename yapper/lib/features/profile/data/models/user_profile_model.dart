import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/profile_entity.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.uid,
    required super.name,
    required super.bio,
    required super.phoneNumber,
    required super.email,
    super.profilePictureUrl,
    required super.emotion,
  });

  factory UserProfileModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfileModel(
      uid: doc.id,
      name: data['name'] ?? '',
      bio: data['bio'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'] ?? '',
      profilePictureUrl: data['profilePictureUrl'],
      emotion: Emotion.values.firstWhere(
        (e) => e.toString() == 'Emotion.${data['emotion']}',
        orElse: () => Emotion.happy,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'bio': bio,
      'phoneNumber': phoneNumber,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
      'emotion': emotion.name,
    };
  }
}
