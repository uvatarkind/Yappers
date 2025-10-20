import 'dart:io';

import '../models/message_model.dart';

abstract class RemoteDataSource {
  /// Returns a stream of message models for the given chat id (real-time)
  Stream<List<MessageModel>> getMessages(String chatId);

  /// Sends a text message (adds to Firestore)
  Future<void> sendTextMessage(MessageModel message, String chatId);

  /// Sends a file message (uploads file then adds message)
  Future<void> sendFileMessage(MessageModel message, File file, String chatId);

  /// Sends a voice message (uploads audio file then adds message)
  Future<void> sendVoiceMessage(MessageModel message, File file, String chatId);

  /// Finds an existing 1:1 chat between two users or creates it and returns the chatId
  Future<String> findOrCreateChat(String myUid, String otherUid);

  /// Marks all messages as read for the given user in the chat
  Future<void> markChatAsRead(String chatId, String userId);
}
