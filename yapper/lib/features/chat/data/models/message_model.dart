import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yapper/features/chat/domain/entities/message.dart';
import 'package:yapper/features/chat/domain/entities/message_type.dart';

class MessageModel {
  final String id;
  final String content;
  final String senderId;
  final String receiverId;
  final MessageType type;
  final Timestamp timestamp;

  MessageModel({
    required this.id,
    required this.content,
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.timestamp,
  });

  factory MessageModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>? ?? {};
    final rawType = data['type'];
    MessageType parsedType;
    try {
      parsedType = MessageType.values.byName(rawType ?? 'text');
    } catch (_) {
      parsedType = MessageType.text;
    }
    final rawTs = data['timestamp'];
    final ts = rawTs is Timestamp ? rawTs : Timestamp.now();

    return MessageModel(
      id: snapshot.id,
      content: data['content'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      type: parsedType,
      timestamp: ts,
    );
  }

  Message toEntity() {
    return Message(
      id: id,
      content: content,
      senderId: senderId,
      receiverId: receiverId,
      type: type,
      timestamp: timestamp.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'senderId': senderId,
      'receiverId': receiverId,
      'type': type.name,
      'timestamp': timestamp,
    };
  }
}
