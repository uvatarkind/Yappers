import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:yapper/features/profile/domain/entities/profile_entity.dart';
import 'package:yapper/injection_container.dart' as di;
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Controllers for edit fields
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  Emotion? _selectedEmotion;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<ProfileBloc>()
        ..add(LoadProfile(FirebaseAuth.instance.currentUser?.uid ?? '')),
      child: BlocListener<ProfileBloc, ProfileState>(
        // Use BlocListener to update controllers without rebuilding the whole page
        listener: (context, state) {
          if (state.userProfile != null) {
            // Check if the controller's text is different from the state's text
            if (_nameController.text != state.userProfile!.name) {
              _nameController.text = state.userProfile!.name;
            }
            if (_bioController.text != state.userProfile!.bio) {
              _bioController.text = state.userProfile!.bio;
            }
            if (_emailController.text != state.userProfile!.email) {
              _emailController.text = state.userProfile!.email;
            }
            if (_phoneController.text != state.userProfile!.phoneNumber) {
              _phoneController.text = state.userProfile!.phoneNumber;
            }
            _selectedEmotion = state.userProfile!.emotion;
          }
        },
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            final emotionColor = state.emotionColor;
            return Scaffold(
              body: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [emotionColor, emotionColor.withOpacity(0.6)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: _buildContent(context, state),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProfileState state) {
    if (state.status == ProfileStatus.loading && state.userProfile == null) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    if (state.status == ProfileStatus.error) {
      return Center(
          child: Text(state.errorMessage ?? 'An error occurred.',
              style: const TextStyle(color: Colors.white)));
    }
    if (state.userProfile == null) {
      return const Center(
          child: Text('No profile data found.',
              style: TextStyle(color: Colors.white)));
    }

    final user = state.userProfile!;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context)),
          actions: [
            TextButton(
              onPressed: () async {
                if (state.userProfile == null) return;
                if (state.isEditing) {
                  // Save
                  final name = _nameController.text.trim();
                  final bio = _bioController.text.trim();
                  final phone = _phoneController.text.trim();
                  // Basic validation
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Name is required')),
                    );
                    return;
                  }
                  final emotionDisplay =
                      (_selectedEmotion ?? state.userProfile!.emotion).name;
                  context.read<ProfileBloc>().add(UpdateProfile(
                        name: name,
                        bio: bio.length > 160 ? bio.substring(0, 160) : bio,
                        phoneNumber: phone,
                        emotionDisplay: emotionDisplay,
                      ));
                } else {
                  // Enter edit mode
                  // Toggle through a state copy; simplest is to rebuild edit view when isEditing true
                  context.read<ProfileBloc>().add(const ToggleEdit(true));
                }
              },
              child: Text(
                state.isEditing ? 'Save' : 'Edit Profile',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: user.profilePictureUrl != null
                        ? NetworkImage(user.profilePictureUrl!)
                        : null,
                    child: user.profilePictureUrl == null
                        ? _InitialsCircle(name: user.name)
                        : null,
                  ),
                  if (state.isEditing)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.photo_camera,
                              color: Colors.white),
                          onPressed: () async {
                            final res = await FilePicker.platform
                                .pickFiles(type: FileType.image);
                            if (res != null && res.files.single.path != null) {
                              final file = File(res.files.single.path!);
                              context
                                  .read<ProfileBloc>()
                                  .add(UploadProfileImage(file));
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever,
                              color: Colors.white),
                          onPressed: () {
                            context
                                .read<ProfileBloc>()
                                .add(const RemoveProfileImage());
                          },
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(user.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _EmotionImage(emotion: user.emotion),
              const SizedBox(height: 30),
            ],
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: state.isEditing
                ? _buildEditView(context, user)
                : _buildReadView(user),
          ),
        )
      ],
    );
  }

  Widget _buildReadView(UserProfile user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('BIO',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(user.bio, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 24),
        const Text('CONTACT',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(user.phoneNumber, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Text(user.email, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildEditView(BuildContext context, UserProfile user) {
    const bioLimit = 160;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('EDIT DETAILS',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          readOnly: true, // Email changes usually go through Auth flow
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: 'Phone number'),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bioController,
          maxLength: bioLimit,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Bio',
            helperText: 'Max 160 characters',
          ),
        ),
        const SizedBox(height: 16),
        const Text('EMOTION',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<Emotion>(
          value: _selectedEmotion ?? user.emotion,
          items: Emotion.values
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.name[0].toUpperCase() + e.name.substring(1)),
                  ))
              .toList(),
          onChanged: (val) {
            setState(() => _selectedEmotion = val);
          },
          decoration: const InputDecoration(
            labelText: 'Select emotion',
          ),
        ),
      ],
    );
  }
}

class _InitialsCircle extends StatelessWidget {
  final String name;
  const _InitialsCircle({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(RegExp(r"\s+")).map((e) => e[0]).take(2).join()
        : '?';
    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.white24,
      child: Text(
        initials.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EmotionImage extends StatelessWidget {
  final Emotion emotion;
  const _EmotionImage({required this.emotion});

  String _assetFor(Emotion e) {
    switch (e) {
      case Emotion.happy:
        return 'assets/images/joy.png';
      case Emotion.sad:
        return 'assets/images/sadness.png';
      case Emotion.angry:
        return 'assets/images/Anger.png';
      case Emotion.disgusted:
        return 'assets/images/disgust.png';
      case Emotion.fear:
        return 'assets/images/fear.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = _assetFor(emotion);
    return Container(
      child: Image.asset(
        path,
        height: 47,
        fit: BoxFit.contain,
      ),
    );
  }
}
