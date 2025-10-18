import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yapper/features/chat/presentation/bloc/chat/chat_bloc.dart';
import 'package:yapper/features/chat/presentation/bloc/chat/chat_event.dart';
import 'package:yapper/features/chat/presentation/bloc/chat/chat_state.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String receiverId;
  final String title;
  final String receiverProfileImageUrl;
  final bool isReceiverOnline;
  final DateTime? lastSeen;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.receiverId,
    required this.title,
    required this.receiverProfileImageUrl,
    this.isReceiverOnline = false,
    this.lastSeen,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  bool _showEmojiPicker = false;
  static const List<String> _emojiList = [
    '😀',
    '😂',
    '😍',
    '👍',
    '🙏',
    '🎉',
    '😢',
    '😎',
    '🔥',
    '😁',
    '😭',
    '🤔',
    '😅',
    '😉',
    '😄',
    '🤗',
    '😇',
    '🤩',
  ];

  String? get _currentUserId => context.read<ChatBloc>().currentUserId;

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(LoadMessages(widget.chatId));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    context
        .read<ChatBloc>()
        .add(SendTextMessage(text, receiverId: widget.receiverId));
    _ctrl.clear();
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'last seen a long time ago';
    final now = DateTime.now();
    final diff = now.difference(lastSeen);
    if (diff.inDays > 0) return 'last seen ${diff.inDays} day(s) ago';
    if (diff.inHours > 0) return 'last seen ${diff.inHours} hour(s) ago';
    if (diff.inMinutes > 0) return 'last seen ${diff.inMinutes} minute(s) ago';
    return 'last seen just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        shadowColor: Colors.transparent,
        flexibleSpace: SafeArea(
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.black),
              ),
              const SizedBox(width: 2),
              CircleAvatar(
                backgroundImage: widget.receiverProfileImageUrl.isNotEmpty
                    ? NetworkImage(widget.receiverProfileImageUrl)
                    : null,
                maxRadius: 20,
                child: widget.receiverProfileImageUrl.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.isReceiverOnline
                          ? 'Online'
                          : _formatLastSeen(widget.lastSeen),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement block functionality
            },
            icon: const Icon(Icons.block, color: Colors.black),
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔹 Chat Messages Area with Background
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    'assets/images/chat_background.jpg',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ChatError) {
                    return Center(child: Text(state.message));
                  }
                  if (state is ChatLoaded) {
                    final messages = state.messages;
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final m = messages[index];
                        final bool isMe = m.senderId == _currentUserId;

                        final bubble = Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          margin: EdgeInsets.only(
                            top: 6,
                            bottom: 6,
                            left: isMe ? 48 : 0,
                            right: isMe ? 0 : 48,
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.purpleAccent.withOpacity(0.95)
                                : Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            m.content,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                        );

                        return Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(
                                    right: 8.0, bottom: 2),
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundImage: NetworkImage(
                                      widget.receiverProfileImageUrl),
                                ),
                              ),
                            Flexible(child: bubble),
                          ],
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),

          // 🔹 Message Input + Emoji Picker + Attachments + Voice
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      // 📎 File Attachment
                      IconButton(
                        onPressed: () {
                          // TODO: implement file picker
                        },
                        icon: const Icon(Icons.attach_file,
                            color: Colors.black54),
                      ),

                      // 😀 Emoji Picker Toggle
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _showEmojiPicker = !_showEmojiPicker;
                          });
                        },
                        icon: const Icon(Icons.emoji_emotions_outlined),
                      ),

                      // ✏️ Message Input Field
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          decoration: InputDecoration(
                            hintText: 'Message...',
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),

                      // 🎙️ Voice Recording
                      IconButton(
                        onPressed: () {
                          // TODO: implement voice recording
                        },
                        icon: const Icon(Icons.mic, color: Colors.black54),
                      ),

                      // 📤 Send
                      IconButton(
                        onPressed: _send,
                        icon: const Icon(Icons.send, color: Colors.purple),
                      ),
                    ],
                  ),

                  // 😊 Emoji Picker
                  if (_showEmojiPicker)
                    SizedBox(
                      height: 250,
                      child: GridView.count(
                        crossAxisCount: 8,
                        padding: const EdgeInsets.all(8),
                        children: [
                          for (final e in _emojiList)
                            GestureDetector(
                              onTap: () {
                                final newText = _ctrl.text + e;
                                _ctrl.text = newText;
                                _ctrl.selection = TextSelection.fromPosition(
                                  TextPosition(offset: newText.length),
                                );
                              },
                              child: Center(
                                child: Text(
                                  e,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
