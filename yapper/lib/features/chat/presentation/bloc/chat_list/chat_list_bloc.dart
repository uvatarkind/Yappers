import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

import 'chat_list_event.dart';
import 'chat_list_state.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final firebase.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  ChatListBloc(
      {required firebase.FirebaseAuth auth,
      required FirebaseFirestore firestore})
      : _auth = auth,
        _firestore = firestore,
        super(const ChatListInitial()) {
    on<LoadChats>(_onLoadChats);
  }

  Future<void> _onLoadChats(
      LoadChats event, Emitter<ChatListState> emit) async {
    emit(const ChatListLoading());
    final user = _auth.currentUser;
    if (user == null) {
      emit(const ChatListError('User not authenticated'));
      return;
    }

    // Cancel any previous subscription if it existed
    await _subscription?.cancel();

    final stream = _firestore
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .asyncMap<ChatListState>((snapshot) async {
      try {
        if (snapshot.docs.isEmpty) {
          return const ChatListLoaded([]);
        }
        final items = await Future.wait(snapshot.docs.map((doc) async {
          final data = doc.data();
          final participants = List<String>.from(data['participants'] ?? []);
          final otherUserId =
              participants.firstWhere((id) => id != user.uid, orElse: () => '');

          String title = data['title'] as String? ?? '';
          String? photoUrl;
          bool isOnline = false;
          DateTime? lastSeen;

          if (otherUserId.isNotEmpty) {
            final userDoc =
                await _firestore.collection('users').doc(otherUserId).get();
            if (userDoc.exists) {
              final userData = userDoc.data() ?? {};
              // Prefer displayName when available for chat title fallback
              final displayNameRaw = userData['displayName'] as String?;
              final displayName = displayNameRaw?.trim();
              if (displayName != null && displayName.isNotEmpty) {
                title = displayName;
              } else {
                final legacyName = (userData['name'] as String?)?.trim();
                if (legacyName != null && legacyName.isNotEmpty) {
                  title = legacyName;
                }
              }
              // Support both legacy photoUrl and new profilePictureUrl fields
              final profilePictureUrl =
                  (userData['profilePictureUrl'] as String?)?.trim();
              final legacyPhotoUrl = (userData['photoUrl'] as String?)?.trim();
              photoUrl = profilePictureUrl?.isNotEmpty == true
                  ? profilePictureUrl
                  : legacyPhotoUrl;
              isOnline = userData['isOnline'] as bool? ?? false;
              final rawLastSeen = userData['lastSeen'];
              if (rawLastSeen is Timestamp) {
                lastSeen = rawLastSeen.toDate();
              }
            }
          }

          final lastMessageData = data['lastMessage'] as Map<String, dynamic>?;
          final lastMessageSnippet = lastMessageData?['content'] as String?;
          DateTime? lastMessageTime;
          final rawLastMessageTs = lastMessageData?['timestamp'];
          if (rawLastMessageTs is Timestamp) {
            lastMessageTime = rawLastMessageTs.toDate();
          }

          bool hasUnread = false;
          final unreadByRaw = data['unreadBy'];
          if (unreadByRaw is Map) {
            final unreadValue = unreadByRaw[user.uid];
            if (unreadValue is bool) {
              hasUnread = unreadValue;
            }
          }

          return ChatListItem(
            chatId: doc.id,
            otherUserId: otherUserId,
            title: title.isNotEmpty ? title : 'Conversation',
            photoUrl: photoUrl,
            isOnline: isOnline,
            lastSeen: lastSeen,
            lastMessageSnippet: lastMessageSnippet,
            lastMessageTime: lastMessageTime,
            hasUnread: hasUnread,
          );
        }).toList());

        return ChatListLoaded(items);
      } catch (e) {
        return ChatListError(e.toString());
      }
    });

    // Use emit.forEach to ensure we don't emit after handler completes
    await emit.forEach<ChatListState>(
      stream,
      onData: (state) => state,
      onError: (error, stackTrace) => ChatListError(error.toString()),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
