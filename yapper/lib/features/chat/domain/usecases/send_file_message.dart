import 'package:yapper/core/error/failure.dart';
import 'package:yapper/features/chat/domain/entities/message.dart';
import 'package:yapper/features/chat/domain/repository/chat_repository.dart';
import 'package:dartz/dartz.dart';
import 'dart:io';


class SendFileMessageUseCase {
  final ChatRepository repository;
  SendFileMessageUseCase(this.repository);

  Future<Either<Failure, void>> call(Message message, File file, String chatId) {
    return repository.sendFileMessage(message, file, chatId);
  }
}