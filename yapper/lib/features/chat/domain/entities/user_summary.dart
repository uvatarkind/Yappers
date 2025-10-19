import 'package:equatable/equatable.dart';

class UserSummary extends Equatable {
  final String uid;
  final String name; // legacy field, prefer displayName
  final String? photoUrl;
  final String displayName;
  final String emotion; // e.g., happy/sad/angry/disgusted/fear

  const UserSummary({
    required this.uid,
    required this.name,
    required this.displayName,
    required this.emotion,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [uid, name, photoUrl, displayName, emotion];
}
