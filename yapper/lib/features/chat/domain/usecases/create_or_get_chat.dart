import 'package:dartz/dartz.dart';
import 'package:yapper/core/error/failure.dart';
import 'package:yapper/features/chat/domain/repository/chat_repository.dart';

class CreateOrGetChatUseCase {
  final ChatRepository repository;
  const CreateOrGetChatUseCase(this.repository);

  Future<Either<Failure, String>> call(
      {required String myUid, required String otherUid}) {
    return repository.createOrGetChat(myUid, otherUid);
  }
}
