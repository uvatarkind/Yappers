import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    String? email,
    String? name,
    String? photoUrl,
    bool isOnline = false,
    DateTime? lastSeen,
  }) : super(
          email: email ?? '',
          name: name ?? '',
          photoUrl: photoUrl,
          isOnline: isOnline,
          lastSeen: lastSeen,
        );

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc, String uid) {
    final data = doc.data() ?? {};

    String? name;
    final dynamic nameData = data['displayName'] ?? data['name'];
    if (nameData is List && nameData.isNotEmpty) {
      name = nameData.first as String?;
    } else if (nameData is String) {
      name = nameData;
    }

    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      name: name ?? '',
      photoUrl: data['photoUrl'] as String?,
      isOnline: data['isOnline'] as bool? ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': name,
      'photoUrl': photoUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
    }..removeWhere((key, value) => value == null);
  }
}
