import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String name;
  final String? photoUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    this.isOnline = false,
    this.lastSeen,
  });

  @override
  List<Object?> get props => [uid, email, name, photoUrl, isOnline, lastSeen];
}
