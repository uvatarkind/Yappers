import 'package:yapper/core/error/failure.dart';
import 'package:yapper/features/chat/domain/entities/message.dart';
import 'package:yapper/features/chat/domain/repository/chat_repository.dart';
import 'package:dartz/dartz.dart';
class GetMessagesStreamUseCase {
  final ChatRepository repository;
  GetMessagesStreamUseCase(this.repository);

  Stream<Either<Failure, List<Message>>> call(String chatId) {
    return repository.getMessages(chatId);
  }
}