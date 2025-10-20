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
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      emotionColor,
                      emotionColor.withOpacity(0.55),
                      Colors.white.withOpacity(0.85),
                      Colors.white,
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
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
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                splashRadius: 24,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
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
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  state.isEditing ? 'Save' : 'Edit Profile',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Column(
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
                    Padding(
                      padding: const EdgeInsets.all(0.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.photo_camera,
                                color: Colors.white),
                            onPressed: () async {
                              final res = await FilePicker.platform
                                  .pickFiles(type: FileType.image);
                              if (res != null &&
                                  res.files.single.path != null) {
                                final file = File(res.files.single.path!);
                                context
                                    .read<ProfileBloc>()
                                    .add(UploadProfileImage(file));
                              }
                            },
                          ),
                          const SizedBox(width: 20),
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
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: state.isEditing
                  ? _buildEditView(context, user, state.emotionColor)
                  : _buildReadView(user, state.emotionColor),
            ),
          ),
        )
      ],
    );
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
    String? helperText,
    bool readOnly = false,
    required Color accentColor,
  }) {
    final radius = BorderRadius.circular(16);
    OutlineInputBorder outline(Color borderColor, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: borderColor, width: width),
        );

    return InputDecoration(
      labelText: label,
      helperText: helperText,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      floatingLabelStyle:
          TextStyle(color: accentColor, fontWeight: FontWeight.w600),
      prefixIcon: Icon(icon, color: Colors.grey.shade600),
      filled: true,
      fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
      border: outline(accentColor.withOpacity(0.2)),
      enabledBorder: outline(accentColor.withOpacity(0.2)),
      focusedBorder: outline(accentColor, 1.4),
    );
  }

  Widget _buildReadView(UserProfile user, Color accentColor) {
    return Column(
      key: const ValueKey('readView'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoCard(
          title: 'About',
          accentColor: accentColor,
          children: [
            _InfoRow(
              icon: Icons.person_outline,
              value: user.name,
              label: 'Name',
              accentColor: accentColor,
            ),
            if (user.bio.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.notes_outlined,
                value: user.bio,
                label: 'Bio',
                accentColor: accentColor,
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        _InfoCard(
          title: 'Contact',
          accentColor: accentColor,
          children: [
            _InfoRow(
              icon: Icons.phone,
              value: user.phoneNumber,
              label: 'Phone',
              accentColor: accentColor,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.email_outlined,
              value: user.email,
              label: 'Email',
              accentColor: accentColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditView(
      BuildContext context, UserProfile user, Color accentColor) {
    const bioLimit = 160;
    return Column(
      key: const ValueKey('editView'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoCard(
          title: 'Profile Details',
          accentColor: accentColor,
          children: [
            TextField(
              controller: _nameController,
              decoration: _fieldDecoration(
                context,
                label: 'Name',
                icon: Icons.person_outline,
                accentColor: accentColor,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: _fieldDecoration(
                context,
                label: 'Email',
                icon: Icons.email_outlined,
                readOnly: true,
                accentColor: accentColor,
              ),
              keyboardType: TextInputType.emailAddress,
              readOnly: true, // Email changes usually go through Auth flow
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: _fieldDecoration(
                context,
                label: 'Phone number',
                icon: Icons.phone,
                accentColor: accentColor,
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bioController,
              maxLength: bioLimit,
              maxLines: 3,
              decoration: _fieldDecoration(
                context,
                label: 'Bio',
                icon: Icons.notes_outlined,
                helperText: 'Max 160 characters',
                accentColor: accentColor,
              ),
              keyboardType: TextInputType.multiline,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _InfoCard(
          title: 'Current Mood',
          accentColor: accentColor,
          children: [
            DropdownButtonFormField<Emotion>(
              value: _selectedEmotion ?? user.emotion,
              items: Emotion.values
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          e.name[0].toUpperCase() + e.name.substring(1),
                        ),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() => _selectedEmotion = val);
              },
              decoration: _fieldDecoration(
                context,
                label: 'Select emotion',
                icon: Icons.mood,
                accentColor: accentColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? label;
  final Color? accentColor;
  const _InfoRow({
    required this.icon,
    required this.value,
    this.label,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    color: accentColor ?? Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              if (label != null) const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
                softWrap: true,
              ),
            ],
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

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Color accentColor;
  const _InfoCard({
    required this.title,
    required this.children,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: accentColor.withOpacity(0.35), width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.titleSmall?.copyWith(
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
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
