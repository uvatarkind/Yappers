import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:yapper/core/error/failures.dart';
import 'package:yapper/features/profile/domain/entities/profile_entity.dart';
import 'package:yapper/features/profile/domain/usecases/get_user_profile.dart';
import 'package:yapper/features/profile/domain/usecases/update_user_profile.dart';
import 'package:yapper/features/profile/domain/usecases/upload_profile_picture.dart';
import 'package:yapper/features/profile/presentation/bloc/profile_event.dart';
import 'package:yapper/features/profile/presentation/bloc/profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetUserProfile getUserProfile;
  final UpdateUserProfile updateUserProfile;
  final UploadProfilePicture uploadProfilePicture;

  ProfileBloc({
    required this.getUserProfile,
    required this.updateUserProfile,
    required this.uploadProfilePicture,
  }) : super(const ProfileState()) {
    on<LoadProfile>(_onLoadProfile);
    on<ChangeEmotion>(_onChangeEmotion);
    on<UpdateProfile>(_onUpdateProfile);
    on<UploadProfileImage>(_onUploadProfileImage);
    on<ToggleEdit>(_onToggleEdit);
    on<RemoveProfileImage>(_onRemoveProfileImage);
  }

  Future<void> _onLoadProfile(
      LoadProfile event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    final Either<Failure, UserProfile> failureOrUser =
        await getUserProfile(event.uid);
    failureOrUser.fold(
      (failure) => emit(state.copyWith(
          status: ProfileStatus.error, errorMessage: 'Failed to load profile')),
      (user) =>
          emit(state.copyWith(status: ProfileStatus.loaded, userProfile: user)),
    );
  }

  Future<void> _onChangeEmotion(
      ChangeEmotion event, Emitter<ProfileState> emit) async {
    if (state.userProfile == null) return;
    final currentUser = state.userProfile!;
    Emotion newEmotion = Emotion.happy;
    final e = event.emotionDisplay.toLowerCase();
    if (e == 'happy') newEmotion = Emotion.happy;
    if (e == 'sad') newEmotion = Emotion.sad;
    if (e == 'angry') newEmotion = Emotion.angry;
    if (e == 'disgusted') newEmotion = Emotion.disgusted;
    if (e == 'fear') newEmotion = Emotion.fear;

    final updatedUser = UserProfile(
      uid: currentUser.uid,
      name: currentUser.name,
      bio: currentUser.bio,
      phoneNumber: currentUser.phoneNumber,
      email: currentUser.email,
      profilePictureUrl: currentUser.profilePictureUrl,
      emotion: newEmotion,
    );

    final Either<Failure, void> failureOrSuccess =
        await updateUserProfile(updatedUser);
    failureOrSuccess.fold(
      (failure) => emit(state.copyWith(
          status: ProfileStatus.error,
          errorMessage: 'Failed to update emotion')),
      (success) => emit(state.copyWith(
          status: ProfileStatus.loaded, userProfile: updatedUser)),
    );
  }

  Future<void> _onUpdateProfile(
      UpdateProfile event, Emitter<ProfileState> emit) async {
    if (state.userProfile == null) return;
    final currentUser = state.userProfile!;
    Emotion newEmotion = Emotion.happy;
    final e = event.emotionDisplay.toLowerCase();
    if (e == 'happy') newEmotion = Emotion.happy;
    if (e == 'sad') newEmotion = Emotion.sad;
    if (e == 'angry') newEmotion = Emotion.angry;
    if (e == 'disgusted') newEmotion = Emotion.disgusted;
    if (e == 'fear') newEmotion = Emotion.fear;

    final updatedUser = UserProfile(
      uid: currentUser.uid,
      name: event.name,
      bio: event.bio,
      phoneNumber: event.phoneNumber,
      email: currentUser.email,
      profilePictureUrl: currentUser.profilePictureUrl,
      emotion: newEmotion,
    );

    final Either<Failure, void> failureOrSuccess =
        await updateUserProfile(updatedUser);
  failureOrSuccess.fold(
    (failure) => emit(state.copyWith(
      status: ProfileStatus.error,
      errorMessage: 'Failed to update profile')),
    (_) => emit(state.copyWith(
      status: ProfileStatus.loaded,
      userProfile: updatedUser,
      isEditing: false)),
  );
  }

  Future<void> _onUploadProfileImage(
      UploadProfileImage event, Emitter<ProfileState> emit) async {
    if (state.userProfile == null) return;
    final uid = state.userProfile!.uid;
    final Either<Failure, String> failureOrUrl =
        await uploadProfilePicture.call(event.image, uid);
    failureOrUrl.fold(
      (failure) => emit(state.copyWith(
          status: ProfileStatus.error, errorMessage: 'Failed to upload image')),
      (url) async {
        final currentUser = state.userProfile!;
        final updatedUser = UserProfile(
          uid: currentUser.uid,
          name: currentUser.name,
          bio: currentUser.bio,
          phoneNumber: currentUser.phoneNumber,
          email: currentUser.email,
          profilePictureUrl: url,
          emotion: currentUser.emotion,
        );
        await updateUserProfile(updatedUser);
        emit(state.copyWith(
            status: ProfileStatus.loaded,
            userProfile: updatedUser,
            isEditing: false));
      },
    );
  }

  void _onToggleEdit(ToggleEdit event, Emitter<ProfileState> emit) {
    emit(state.copyWith(isEditing: event.isEditing));
  }

  Future<void> _onRemoveProfileImage(
      RemoveProfileImage event, Emitter<ProfileState> emit) async {
    if (state.userProfile == null) return;
    final currentUser = state.userProfile!;
    final updatedUser = UserProfile(
      uid: currentUser.uid,
      name: currentUser.name,
      bio: currentUser.bio,
      phoneNumber: currentUser.phoneNumber,
      email: currentUser.email,
      profilePictureUrl: null,
      emotion: currentUser.emotion,
    );
    final res = await updateUserProfile(updatedUser);
    res.fold(
      (_) => emit(state.copyWith(
          status: ProfileStatus.error,
          errorMessage: 'Failed to remove image')),
      (_) => emit(state.copyWith(
          status: ProfileStatus.loaded,
          userProfile: updatedUser,
          isEditing: false)),
    );
  }
}
