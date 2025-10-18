import 'package:equatable/equatable.dart';
import 'package:yapper/features/chat/domain/entities/message.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object> get props => [];
}

class LoadMessages extends ChatEvent {
  final String chatId;
  const LoadMessages(this.chatId);
}

class MessagesUpdated extends ChatEvent {
  final List<Message> messages;
  const MessagesUpdated(this.messages);
}

class SendTextMessage extends ChatEvent {
  final String text;
  final String? receiverId;
  const SendTextMessage(this.text, {this.receiverId});
}

class SendFileMessage extends ChatEvent {
  // Can be an image, audio file, etc.
}
