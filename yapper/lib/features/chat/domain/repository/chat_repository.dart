import 'dart:io';
import 'package:dartz/dartz.dart'; // A package for functional error handling
import 'package:yapper/core/error/failure.dart';
import '../entities/message.dart';

abstract class ChatRepository {
  Stream<Either<Failure, List<Message>>> getMessages(String chatId);
  Future<Either<Failure, void>> sendTextMessage(Message message, String chatId);
  Future<Either<Failure, void>> sendVoiceMessage(
      Message message, File audioFile, String chatId);
  Future<Either<Failure, void>> sendFileMessage(
      Message message, File file, String chatId);
  Future<Either<Failure, String>> createOrGetChat(
      String myUid, String otherUid);
  Future<Either<Failure, void>> markChatAsRead(String chatId, String userId);
}
