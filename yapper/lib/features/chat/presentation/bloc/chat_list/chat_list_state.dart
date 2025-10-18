import 'package:equatable/equatable.dart';

class ChatListState extends Equatable {
  const ChatListState();

  @override
  List<Object?> get props => [];
}

class ChatListInitial extends ChatListState {
  const ChatListInitial();
}

class ChatListLoading extends ChatListState {
  const ChatListLoading();
}

class ChatListLoaded extends ChatListState {
  final List<ChatListItem> chats;
  const ChatListLoaded(this.chats);

  @override
  List<Object?> get props => [chats];
}

class ChatListError extends ChatListState {
  final String message;
  const ChatListError(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatListItem extends Equatable {
  final String chatId;
  final String otherUserId;
  final String title;
  final String? photoUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? lastMessageSnippet;
  final DateTime? lastMessageTime;

  const ChatListItem({
    required this.chatId,
    required this.otherUserId,
    required this.title,
    this.photoUrl,
    this.isOnline = false,
    this.lastSeen,
    this.lastMessageSnippet,
    this.lastMessageTime,
  });

  @override
  List<Object?> get props => [
        chatId,
        otherUserId,
        title,
        photoUrl,
        isOnline,
        lastSeen,
        lastMessageSnippet,
        lastMessageTime,
      ];
}
