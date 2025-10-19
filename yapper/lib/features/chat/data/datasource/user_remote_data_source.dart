import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_summary.dart';

abstract class UserRemoteDataSource {
  Stream<List<UserSummary>> getRecentUsersStream({int limit});
  Future<List<UserSummary>> getRecentUsersOnce({int limit});
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final FirebaseFirestore firestore;
  UserRemoteDataSourceImpl(this.firestore);

  @override
  Stream<List<UserSummary>> getRecentUsersStream({int limit = 12}) {
    return firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) {
              final data = d.data();
              final displayName =
                  (data['displayName'] as String?)?.trim() ?? 'User';
              final legacyName = (data['name'] as String?)?.trim();
              final emotion = (data['emotion'] as String?)?.trim() ??
                  'happy'; // default to joy
              return UserSummary(
                uid: d.id,
                name: legacyName ?? displayName,
                displayName: displayName,
                emotion: emotion,
                photoUrl: data['profilePictureUrl'] as String? ??
                    data['photoUrl'] as String?,
              );
            }).toList());
  }

  @override
  Future<List<UserSummary>> getRecentUsersOnce({int limit = 12}) async {
    final snap = await firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      final displayName = (data['displayName'] as String?)?.trim() ?? 'User';
      final legacyName = (data['name'] as String?)?.trim();
      final emotion = (data['emotion'] as String?)?.trim() ?? 'happy';
      return UserSummary(
        uid: d.id,
        name: legacyName ?? displayName,
        displayName: displayName,
        emotion: emotion,
        photoUrl:
            data['profilePictureUrl'] as String? ?? data['photoUrl'] as String?,
      );
    }).toList();
  }
}
