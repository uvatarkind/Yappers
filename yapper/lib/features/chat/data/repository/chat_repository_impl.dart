import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/datasource/remote_datasource.dart';
import '../../data/models/message_model.dart';
import '../../domain/entities/message.dart';
import '../../domain/repository/chat_repository.dart';
import '../../../../core/error/failure.dart'; // We will create this next
import 'package:dartz/dartz.dart';

class ChatRepositoryImpl implements ChatRepository {
  final RemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<Either<Failure, List<Message>>> getMessages(String chatId) {
    return remoteDataSource.getMessages(chatId).map((models) {
      try {
        final messageEntities =
            models.map((model) => model.toEntity()).toList();
        return Right<Failure, List<Message>>(messageEntities);
      } catch (e) {
        return Left<Failure, List<Message>>(ServerFailure(e.toString()));
      }
    }).handleError((error) {
      return Left<Failure, List<Message>>(ServerFailure(error.toString()));
    });
  }

  @override
  Future<Either<Failure, void>> sendTextMessage(
      Message message, String chatId) async {
    try {
      final messageModel = MessageModel(
        id: message.id,
        content: message.content,
        senderId: message.senderId,
        receiverId: message.receiverId,
        type: message.type,
        timestamp: Timestamp.fromDate(message.timestamp),
      );
      await remoteDataSource.sendTextMessage(messageModel, chatId);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendFileMessage(
      Message message, File file, String chatId) async {
    try {
      final messageModel = MessageModel(
        id: message.id,
        content: message.content,
        senderId: message.senderId,
        receiverId: message.receiverId,
        type: message.type,
        timestamp: Timestamp.fromDate(message.timestamp),
      );
      await remoteDataSource.sendFileMessage(messageModel, file, chatId);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendVoiceMessage(
      Message message, File voiceFile, String chatId) async {
    try {
      final messageModel = MessageModel(
        id: message.id,
        content: message.content,
        senderId: message.senderId,
        receiverId: message.receiverId,
        type: message.type,
        timestamp: Timestamp.fromDate(message.timestamp),
      );
      await remoteDataSource.sendVoiceMessage(messageModel, voiceFile, chatId);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createOrGetChat(
      String myUid, String otherUid) async {
    try {
      final chatId = await remoteDataSource.findOrCreateChat(myUid, otherUid);
      return Right(chatId);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markChatAsRead(
      String chatId, String userId) async {
    try {
      await remoteDataSource.markChatAsRead(chatId, userId);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
