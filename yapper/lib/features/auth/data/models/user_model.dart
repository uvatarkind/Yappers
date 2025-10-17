import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({required String uid, String? email, String? name})
      : super(uid: uid, email: email ?? '', name: name ?? '');
  }