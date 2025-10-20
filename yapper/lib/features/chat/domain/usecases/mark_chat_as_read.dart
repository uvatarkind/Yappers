import 'package:dartz/dartz.dart';
import 'package:yapper/core/error/failure.dart';
import 'package:yapper/features/chat/domain/repository/chat_repository.dart';

class MarkChatAsReadUseCase {
  final ChatRepository repository;

  MarkChatAsReadUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String chatId,
    required String userId,
  }) {
    return repository.markChatAsRead(chatId, userId);
  }
}
