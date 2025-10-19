import 'dart:io';

import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  final String uid;
  const LoadProfile(this.uid);

  @override
  List<Object?> get props => [uid];
}

class ChangeEmotion extends ProfileEvent {
  final String emotionDisplay;
  const ChangeEmotion(this.emotionDisplay);

  @override
  List<Object?> get props => [emotionDisplay];
}

class UpdateProfile extends ProfileEvent {
  final String name;
  final String bio;
  final String phoneNumber;
  final String emotionDisplay;

  const UpdateProfile(
      {required this.name,
      required this.bio,
      required this.phoneNumber,
      required this.emotionDisplay});

  @override
  List<Object?> get props => [name, bio, phoneNumber, emotionDisplay];
}

class UploadProfileImage extends ProfileEvent {
  final File image;
  const UploadProfileImage(this.image);

  @override
  List<Object?> get props => [image.path];
}

class ToggleEdit extends ProfileEvent {
  final bool isEditing;
  const ToggleEdit(this.isEditing);

  @override
  List<Object?> get props => [isEditing];
}

class RemoveProfileImage extends ProfileEvent {
  const RemoveProfileImage();
}
