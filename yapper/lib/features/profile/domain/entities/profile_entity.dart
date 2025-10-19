import 'package:equatable/equatable.dart';

enum Emotion { happy, sad, angry, disgusted, fear }

class UserProfile extends Equatable {
  final String uid;
  final String name;
  final String bio;
  final String phoneNumber;
  final String email;
  final String? profilePictureUrl;
  final Emotion emotion;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.bio,
    required this.phoneNumber,
    required this.email,
    this.profilePictureUrl,
    required this.emotion,
  });

  @override
  List<Object?> get props =>
      [uid, name, bio, phoneNumber, email, profilePictureUrl, emotion];
}
