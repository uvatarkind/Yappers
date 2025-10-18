import 'package:equatable/equatable.dart';
import 'package:yapper/features/chat/domain/entities/message_type.dart';
// ... import MessageType enum

class Message extends Equatable {
  final String id;
  final String content;
  final String senderId;
  final String receiverId;
  final MessageType type;
  final DateTime timestamp;

  const Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id];
}
