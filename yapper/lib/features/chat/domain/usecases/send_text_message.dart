import 'package:yapper/features/chat/domain/entities/message.dart';
import 'package:yapper/features/chat/domain/repository/chat_repository.dart';
import 'package:yapper/core/error/failure.dart';
import 'package:dartz/dartz.dart';


class SendTextMessageUseCase {
  final ChatRepository repository;
  SendTextMessageUseCase(this.repository);

  Future<Either<Failure, void>> call(Message message, String chatId) {
    return repository.sendTextMessage(message, chatId);
  }
}