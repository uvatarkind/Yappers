import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yapper/features/profile/presentation/bloc/theme/theme_bloc.dart';
import 'package:yapper/features/profile/presentation/bloc/theme/theme_event.dart';
import 'package:yapper/features/profile/domain/entities/profile_entity.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Notification Settings
          _buildSection(
            context,
            title: 'Notifications',
            children: [
              SwitchListTile(
                title: const Text('Message Notifications'),
                subtitle:
                    const Text('Get notified when you receive new messages'),
                value: true,
                onChanged: (value) {
                  // Implement notification settings
                },
              ),
              SwitchListTile(
                title: const Text('Group Notifications'),
                subtitle: const Text('Get notified for group messages'),
                value: true,
                onChanged: (value) {
                  // Implement notification settings
                },
              ),
            ],
          ),

          // Privacy Settings
          _buildSection(
            context,
            title: 'Privacy',
            children: [
              ListTile(
                title: const Text('Online Status'),
                subtitle: const Text('Control who can see when you\'re online'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to online status settings
                },
              ),
              ListTile(
                title: const Text('Blocked Users'),
                subtitle: const Text('Manage your blocked users list'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to blocked users
                },
              ),
            ],
          ),

          // Account Settings
          _buildSection(
            context,
            title: 'Account',
            children: [
              ListTile(
                title: const Text('Change Password'),
                leading: const Icon(Icons.lock_outline),
                onTap: () {
                  // Navigate to change password
                },
              ),
              ListTile(
                title: const Text('Delete Account'),
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                onTap: () {
                  // Show delete account confirmation
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  Widget _buildEmotionChip(
    BuildContext context, {
    required Emotion emotion,
    required String label,
    required IconData icon,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () {
        context.read<ThemeBloc>().add(EmotionChanged(emotion));
      },
    );
  }
}
