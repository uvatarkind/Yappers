import 'package:flutter/material.dart';
import 'package:yapper/features/chat/presentation/pages/chat_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yapper/injection_container.dart' as di;
import 'package:yapper/features/chat/presentation/bloc/chat/chat_bloc.dart';
import 'package:yapper/features/chat/presentation/bloc/chat_list/chat_list_bloc.dart';
import 'package:yapper/features/chat/presentation/bloc/chat_list/chat_list_event.dart';
import 'package:yapper/features/chat/presentation/bloc/chat_list/chat_list_state.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<ChatListBloc>()..add(const LoadChats()),
      child: const _ChatListView(),
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
                _RecentMatches(),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile tapped')),
                );
              } else if (value == 'settings') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings tapped')),
                );
              } else if (value == 'logout') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out')),
                );
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

class _RecentMatches extends StatelessWidget {
  const _RecentMatches();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        children: const [
          RecentMatch(
            name: 'Selena',
            imageUrl: 'https://i.pravatar.cc/150?img=32',
          ),
          RecentMatch(
            name: 'Mia',
            imageUrl: 'https://i.pravatar.cc/150?img=33',
          ),
          RecentMatch(
            name: 'Clara',
            imageUrl: 'https://i.pravatar.cc/150?img=35',
          ),
          RecentMatch(
            name: 'Fabian',
            imageUrl: 'https://i.pravatar.cc/150?img=60',
          ),
          RecentMatch(
            name: 'George',
            imageUrl: 'https://i.pravatar.cc/150?img=59',
          ),
        ],
      ),
    );
  }
}

class _ChatListSection extends StatelessWidget {
  const _ChatListSection();

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
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ChatListError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          if (state is ChatListLoaded) {
            if (state.chats.isEmpty) {
              return const Center(
                child: Text(
                  'No conversations yet. Start chatting!',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return ListView.separated(
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

class RecentMatch extends StatelessWidget {
  final String name;
  final String imageUrl;

  const RecentMatch({super.key, required this.name, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Colors.orange, Colors.pink, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              backgroundImage: NetworkImage(imageUrl),
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
        leading: _ChatAvatar(imageUrl: imageUrl, name: name, isOnline: isOnline),
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
          backgroundImage:
              (imageUrl != null && imageUrl!.isNotEmpty) ? NetworkImage(imageUrl!) : null,
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
