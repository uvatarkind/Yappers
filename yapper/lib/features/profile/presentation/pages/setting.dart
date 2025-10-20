import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _messageNotifications = true;
  bool _groupNotifications = true;

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // Notification Settings
          _buildSection(
            context,
            title: 'Notifications',
            accentColor: accentColor,
            children: [
              SwitchListTile(
                title: const Text('Message Notifications'),
                subtitle:
                    const Text('Get notified when you receive new messages'),
                value: _messageNotifications,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                tileColor: Colors.white,
                activeColor: Colors.white,
                activeTrackColor: accentColor,
                inactiveTrackColor: accentColor.withOpacity(0.12),
                controlAffinity: ListTileControlAffinity.trailing,
                onChanged: (value) {
                  setState(() => _messageNotifications = value);
                },
              ),
              SwitchListTile(
                title: const Text('Group Notifications'),
                subtitle: const Text('Get notified for group messages'),
                value: _groupNotifications,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                tileColor: Colors.white,
                activeColor: Colors.white,
                activeTrackColor: accentColor,
                inactiveTrackColor: accentColor.withOpacity(0.12),
                controlAffinity: ListTileControlAffinity.trailing,
                onChanged: (value) {
                  setState(() => _groupNotifications = value);
                },
              ),
            ],
          ),

          // Privacy Settings
          _buildSection(
            context,
            title: 'Privacy',
            accentColor: accentColor,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: accentColor.withOpacity(0.12),
                  foregroundColor: accentColor,
                  child: const Icon(Icons.visibility_outlined),
                ),
                title: const Text('Online Status'),
                subtitle: const Text('Control who can see when you\'re online'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                onTap: () {
                  // Navigate to online status settings
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: accentColor.withOpacity(0.12),
                  foregroundColor: accentColor,
                  child: const Icon(Icons.block_outlined),
                ),
                title: const Text('Blocked Users'),
                subtitle: const Text('Manage your blocked users list'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                onTap: () {
                  // Navigate to blocked users
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
    required Color accentColor,
    required List<Widget> children,
  }) {
    final spacedChildren = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i != children.length - 1) {
        spacedChildren.add(const SizedBox(height: 12));
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FB),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: accentColor.withOpacity(0.15), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 16),
          ...spacedChildren,
        ],
      ),
    );
  }
}
