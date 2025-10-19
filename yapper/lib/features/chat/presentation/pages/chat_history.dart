import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:yapper/features/chat/presentation/pages/chat_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yapper/features/profile/presentation/pages/profile_page.dart';
import 'package:yapper/injection_container.dart' as di;
import 'package:yapper/features/chat/presentation/bloc/chat/chat_bloc.dart';
import 'package:yapper/features/chat/presentation/bloc/chat_list/chat_list_bloc.dart';
import 'package:yapper/features/chat/presentation/bloc/chat_list/chat_list_event.dart';
import 'package:yapper/features/chat/presentation/bloc/chat_list/chat_list_state.dart';
import 'package:yapper/core/widgets/loading_widget.dart';
import 'package:yapper/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:yapper/features/auth/presentation/bloc/auth_event.dart';
import 'package:yapper/features/auth/presentation/bloc/auth_state.dart';
import 'package:yapper/features/auth/presentation/pages/login.dart';
import 'package:yapper/features/chat/presentation/bloc/recent_users/recent_users_bloc.dart';
import 'package:yapper/features/chat/domain/usecases/create_or_get_chat.dart';
import 'package:yapper/features/profile/presentation/pages/setting.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) => di.sl<ChatListBloc>()..add(const LoadChats())),
        BlocProvider(create: (_) => di.sl<AuthBloc>()),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        child: const _ChatListView(),
      ),
    );
  }
}

class _ChatListView extends StatelessWidget {
  const _ChatListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: SafeArea(
        child: Stack(
          children: [
            // 🔹 Background Image
            Positioned(
              top: 80,
              left: 50,
              child: SizedBox(
                width: 250,
                height: 250,
                child: Image.asset(
                  'assets/images/(O).png', // 👈 Make sure this exists in pubspec.yaml
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // 🔹 Main Content
            Column(
              children: const [
                _TopBar(),
                SizedBox(height: 10.0),
                _RecentYappers(),
                SizedBox(height: 12.0),
                Expanded(child: _ChatListSection()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 10.0,
      ),
      child: Row(
        children: [
          PopupMenuButton<String>(
            color: Colors.white,
            icon: const Icon(Icons.menu, color: Colors.white, size: 28),
            onSelected: (value) {
              if (value == 'profile') {
                if (uid != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfilePage(),
                    ),
                  );
                } else {
                  // Handle case where user is not logged in, though this is unlikely here.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Could not get user information.')),
                  );
                }
              } else if (value == 'settings') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SettingsPage(),
                  ),
                );
              } else if (value == 'logout') {
                context.read<AuthBloc>().add(SignOutRequested());
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'profile', child: Text('Profile')),
              PopupMenuItem(value: 'settings', child: Text('Settings')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
          const Spacer(),
          const Text(
            'Recent Yappers',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _RecentYappers extends StatelessWidget {
  const _RecentYappers();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: BlocProvider(
        create: (_) => di.sl<RecentUsersBloc>()..add(const LoadRecentUsers()),
        child: BlocBuilder<RecentUsersBloc, RecentUsersState>(
          builder: (context, state) {
            if (state is RecentUsersLoading || state is RecentUsersInitial) {
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemCount: 6,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, __) => const _AvatarSkeleton(),
              );
            }
            if (state is RecentUsersError) {
              return const Center(
                child: Text(
                  'Failed to load users',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }
            if (state is RecentUsersLoaded) {
              final users = state.users;
              if (users.isEmpty) {
                return const Center(
                  child: Text(
                    'No recent yappers',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, index) {
                  final u = users[index];
                  return _UserAvatarBubble(
                    name: u.displayName.isNotEmpty ? u.displayName : u.name,
                    photoUrl: u.photoUrl ?? '',
                    uid: u.uid,
                    emotion: u.emotion,
                    onTap: () async {
                      final me = FirebaseAuth.instance.currentUser;
                      if (me == null) return;
                      // Create or get chat id
                      final usecase = di.sl<CreateOrGetChatUseCase>();
                      final result =
                          await usecase(myUid: me.uid, otherUid: u.uid);
                      result.fold(
                        (failure) => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Failed to start chat: ${failure.message}')),
                        ),
                        (chatId) async {
                          // Refresh chat list so it appears
                          context.read<ChatListBloc>().add(const LoadChats());
                          // Fetch minimal user info for header (if not already in list)
                          String title = u.name;
                          final imageUrl = u.photoUrl ?? '';
                          // Navigate to chat screen
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BlocProvider<ChatBloc>(
                                create: (_) => di.sl<ChatBloc>(),
                                child: ChatScreen(
                                  chatId: chatId,
                                  title: title,
                                  receiverProfileImageUrl: imageUrl,
                                  isReceiverOnline: false,
                                  lastSeen: null,
                                  receiverId: u.uid,
                                ),
                              ),
                            ),
                          );
                          // After returning, refresh list again in case lastMessage changed
                          context.read<ChatListBloc>().add(const LoadChats());
                        },
                      );
                    },
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ChatListSection extends StatelessWidget {
  const _ChatListSection();

  Future<void> _onRefresh(BuildContext context) async {
    final bloc = context.read<ChatListBloc>();
    bloc.add(const LoadChats());
    await bloc.stream.firstWhere(
      (s) => s is ChatListLoaded || s is ChatListError,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
      ),
      child: BlocBuilder<ChatListBloc, ChatListState>(
        builder: (context, state) {
          if (state is ChatListLoading || state is ChatListInitial) {
            return const YapperLoadingWidget();
          }

          if (state is ChatListError) {
            return RefreshIndicator(
              onRefresh: () => _onRefresh(context),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 24.0),
                    child: Center(
                      child: Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is ChatListLoaded) {
            if (state.chats.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => _onRefresh(context),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    _EmptyChatIndicator(),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => _onRefresh(context),
              child: ListView.separated(
                itemCount: state.chats.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final chat = state.chats[index];
                  return ChatItem(
                    chatId: chat.chatId,
                    otherUserId: chat.otherUserId,
                    name: chat.title,
                    message: chat.lastMessageSnippet ?? 'Say hi 👋',
                    time: chat.lastMessageTime != null
                        ? _formatTime(context, chat.lastMessageTime!)
                        : '',
                    imageUrl: chat.photoUrl,
                    hasUnread: false, // TODO: wire unread status when available
                    isOnline: chat.isOnline,
                    lastSeen: chat.lastSeen,
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _formatTime(BuildContext context, DateTime dateTime) {
    final now = DateTime.now();
    if (now.difference(dateTime).inDays == 0) {
      return TimeOfDay.fromDateTime(dateTime).format(context);
    }
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }
}

class _UserAvatarBubble extends StatelessWidget {
  final String uid;
  final String name;
  final String photoUrl;
  final VoidCallback? onTap;
  final String? emotion; // happy|sad|angry|disgusted|fear

  const _UserAvatarBubble({
    Key? key,
    required this.uid,
    required this.name,
    required this.photoUrl,
    this.emotion,
    this.onTap,
  }) : super(key: key);

  Color _colorFor(String input) {
    // Stable-ish hash using sum of code units (avoids non-deterministic hashCode across runs)
    final code = input.codeUnits.fold<int>(0, (p, c) => p + c);
    const palette = <Color>[
      Color(0xFFB39DDB), // DeepPurple 200
      Color(0xFFFFAB91), // Deep Orange 200
      Color(0xFF80CBC4), // Teal 200
      Color(0xFF90CAF9), // Blue 200
      Color(0xFFF48FB1), // Pink 200
      Color(0xFFA5D6A7), // Green 200
      Color(0xFFFFE082), // Amber 200
      Color(0xFF81D4FA), // Light Blue 200
    ];
    return palette[code % palette.length];
  }

  Color _ringColor() {
    switch ((emotion ?? 'happy').toLowerCase()) {
      case 'sad':
        return const Color(0xFF64B5F6); // Blue 300
      case 'angry':
        return const Color(0xFFE57373); // Red 300
      case 'disgusted':
        return const Color(0xFF81C784); // Green 300
      case 'fear':
        return const Color(0xFFBA68C8); // Purple 300
      case 'happy':
      default:
        return const Color(0xFFFFF176); // Yellow 300 (joy default)
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _colorFor(uid.isNotEmpty ? uid : name);
    final initials = name.isNotEmpty
        ? name
            .trim()
            .split(RegExp(r'\s+'))
            .map((e) => e[0])
            .take(2)
            .join()
            .toUpperCase()
        : '?';
    final brightness = ThemeData.estimateBrightnessForColor(bg);
    final fg = brightness == Brightness.dark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _ringColor(),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: photoUrl.isNotEmpty ? Colors.white : bg,
                backgroundImage:
                    photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty
                    ? Text(
                        initials,
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 6.0),
            SizedBox(
              width: 70,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarSkeleton extends StatelessWidget {
  const _AvatarSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 60,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }
}

// 🔹 Chat Item Widget
class ChatItem extends StatelessWidget {
  final String chatId;
  final String otherUserId;
  final String name;
  final String message;
  final String time;
  final String? imageUrl;
  final bool hasUnread;
  final bool isOnline;
  final DateTime? lastSeen;

  const ChatItem({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.name,
    required this.message,
    required this.time,
    required this.imageUrl,
    required this.hasUnread,
    required this.isOnline,
    required this.lastSeen,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlocProvider<ChatBloc>(
              create: (_) => di.sl<ChatBloc>(),
              child: ChatScreen(
                chatId: chatId,
                title: name,
                receiverProfileImageUrl: imageUrl ?? '',
                isReceiverOnline: isOnline,
                lastSeen: lastSeen,
                receiverId: otherUserId,
              ),
            ),
          ),
        );
      },
      child: ListTile(
        visualDensity: VisualDensity.compact,
        leading:
            _ChatAvatar(imageUrl: imageUrl, name: name, isOnline: isOnline),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15.0,
          ),
        ),
        subtitle: Text(
          message,
          style: const TextStyle(color: Colors.grey, fontSize: 13.0),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              time,
              style: const TextStyle(color: Colors.grey, fontSize: 12.0),
            ),
            const SizedBox(height: 4.0),
            if (hasUnread)
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Colors.pink,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 7, width: 7),
          ],
        ),
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final bool isOnline;

  const _ChatAvatar({
    required this.imageUrl,
    required this.name,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.trim().split(RegExp(r'\s+')).map((e) => e[0]).take(2).join()
        : '?';

    return Stack(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.deepPurple.shade100,
          backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
              ? NetworkImage(imageUrl!)
              : null,
          child: (imageUrl == null || imageUrl!.isEmpty)
              ? Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        if (isOnline)
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyChatIndicator extends StatelessWidget {
  const _EmptyChatIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No conversations yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start a new chat or pull down to refresh.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}
