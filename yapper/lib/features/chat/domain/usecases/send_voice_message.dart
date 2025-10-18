import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:yapper/core/error/failure.dart';
import 'package:yapper/features/chat/domain/entities/message.dart';
import 'package:yapper/features/chat/domain/repository/chat_repository.dart';


class SendVoiceMessageUseCase {
  final ChatRepository repository;
  SendVoiceMessageUseCase(this.repository);

  Future<Either<Failure, void>> call(Message message, File audioFile, String chatId) {
    // The business logic is simply to pass the call to the repository
    return repository.sendVoiceMessage(message, audioFile, chatId);
  }
}