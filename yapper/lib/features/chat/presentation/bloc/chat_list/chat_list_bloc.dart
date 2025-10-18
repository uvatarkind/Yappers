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

  void _onLoadChats(LoadChats event, Emitter<ChatListState> emit) {
    emit(const ChatListLoading());
    final user = _auth.currentUser;
    if (user == null) {
      emit(const ChatListError('User not authenticated'));
      return;
    }

    _subscription?.cancel();

    _subscription = _firestore
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen((snapshot) async {
      try {
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
              title = userData['displayName'] as String? ?? title;
              photoUrl = userData['photoUrl'] as String?;
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

          return ChatListItem(
            chatId: doc.id,
            otherUserId: otherUserId,
            title: title.isNotEmpty ? title : 'Conversation',
            photoUrl: photoUrl,
            isOnline: isOnline,
            lastSeen: lastSeen,
            lastMessageSnippet: lastMessageSnippet,
            lastMessageTime: lastMessageTime,
          );
        }).toList());

        emit(ChatListLoaded(items));
      } catch (e) {
        emit(ChatListError(e.toString()));
      }
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
