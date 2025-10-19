import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/profile_entity.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileState extends Equatable {
  final UserProfile? userProfile;
  final ProfileStatus status;
  final bool isEditing;
  final String? errorMessage;

  const ProfileState({
    this.userProfile,
    this.status = ProfileStatus.initial,
    this.isEditing = false,
    this.errorMessage,
  });

  Color get emotionColor {
    if (userProfile == null) return Colors.grey;
    switch (userProfile!.emotion) {
      case Emotion.happy:
        return Colors.yellow;
      case Emotion.sad:
        return Colors.blue;
      case Emotion.angry:
        return Colors.red;
      case Emotion.disgusted:
        return Colors.green;
      case Emotion.fear:
        return Colors.purple;
    }
  }

  ProfileState copyWith({
    UserProfile? userProfile,
    ProfileStatus? status,
    bool? isEditing,
    String? errorMessage,
  }) {
    return ProfileState(
      userProfile: userProfile ?? this.userProfile,
      status: status ?? this.status,
      isEditing: isEditing ?? this.isEditing,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [userProfile, status, isEditing, errorMessage];
}
