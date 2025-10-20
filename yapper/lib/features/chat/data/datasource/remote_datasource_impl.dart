import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yapper/features/chat/data/models/message_model.dart';
import 'package:yapper/features/chat/data/datasource/remote_datasource.dart';
import 'package:yapper/features/storage/supabase_storage_service.dart';
import 'package:uuid/uuid.dart';
import 'package:yapper/features/chat/domain/entities/message_type.dart';

class SupabaseRemoteDataSource implements RemoteDataSource {
  final FirebaseFirestore _firestore;
  final SupabaseStorageService _storage;
  final Uuid _uuid;

  SupabaseRemoteDataSource(this._firestore, this._storage, this._uuid);

  // Get a real-time stream of messages
  @override
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromSnapshot(doc))
            .toList());
  }

  // Send a text message
  @override
  Future<void> sendTextMessage(MessageModel message, String chatId) async {
    final chatRef = _firestore.collection('chats').doc(chatId);
    final batch = _firestore.batch();
    final messagesRef = chatRef.collection('messages').doc();
    batch.set(messagesRef, message.toMap());
    batch.set(
        chatRef,
        {
          'lastMessage': {
            'content': message.content,
            'senderId': message.senderId,
            'timestamp': FieldValue.serverTimestamp(),
            'type': message.type.name,
          },
          'updatedAt': FieldValue.serverTimestamp(),
          'unreadBy.${message.senderId}': false,
          'unreadBy.${message.receiverId}': true,
        },
        SetOptions(merge: true));
    await batch.commit();
  }

  // Upload a file and send the message
  @override
  Future<void> sendFileMessage(
      MessageModel message, File file, String chatId) async {
    // 1. Upload file to Supabase Storage
    // Preserve file extension if available
    final ext = file.path.split('.').length > 1
        ? '.${file.path.split('.').last.toLowerCase()}'
        : '';
    final fileName = '${_uuid.v4()}$ext';
    final path = 'chat_files/$chatId/$fileName';
    // Light content type inference
    String? contentType;
    final lower = file.path.toLowerCase();
    if (lower.endsWith('.png')) contentType = 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg'))
      contentType = 'image/jpeg';
    if (lower.endsWith('.gif')) contentType = 'image/gif';
    if (lower.endsWith('.webp')) contentType = 'image/webp';
    if (lower.endsWith('.pdf')) contentType = 'application/pdf';
    await _storage.uploadFile(path: path, file: file, contentType: contentType);
    final downloadUrl = _storage.getPublicUrl(path);

    // 2. Create a new message with the download URL
    final messageToSend = MessageModel(
      id: message.id.isNotEmpty ? message.id : _uuid.v4(),
      content: downloadUrl,
      senderId: message.senderId,
      receiverId: message.receiverId,
      type: message.type,
      timestamp: Timestamp.now(),
    );

    // 3. Add message data to Firestore
    final chatRef = _firestore.collection('chats').doc(chatId);
    final batch = _firestore.batch();
    final messagesRef = chatRef.collection('messages').doc();
    batch.set(messagesRef, messageToSend.toMap());
    batch.set(
        chatRef,
        {
          'lastMessage': {
            'content': '[file]',
            'senderId': message.senderId,
            'timestamp': FieldValue.serverTimestamp(),
            'type': message.type.name,
          },
          'updatedAt': FieldValue.serverTimestamp(),
          'unreadBy.${message.senderId}': false,
          'unreadBy.${message.receiverId}': true,
        },
        SetOptions(merge: true));
    await batch.commit();
  }

  // Upload a voice file and send the message
  @override
  Future<void> sendVoiceMessage(
      MessageModel message, File file, String chatId) async {
    // 1. Upload voice file to Supabase Storage
    final ext = file.path.split('.').length > 1
        ? '.${file.path.split('.').last.toLowerCase()}'
        : '.m4a';
    final fileName = '${_uuid.v4()}$ext';
    final path = 'chat_voice/$chatId/$fileName';
    await _storage.uploadFile(path: path, file: file, contentType: 'audio/mp4');
    final downloadUrl = _storage.getPublicUrl(path);

    // 2. Create a new message with the download URL and audio type
    final messageToSend = MessageModel(
      id: message.id.isNotEmpty ? message.id : _uuid.v4(),
      content: downloadUrl,
      senderId: message.senderId,
      receiverId: message.receiverId,
      type: MessageType.audio,
      timestamp: Timestamp.now(),
    );

    // 3. Add message data to Firestore
    final chatRef = _firestore.collection('chats').doc(chatId);
    final batch = _firestore.batch();
    final messagesRef = chatRef.collection('messages').doc();
    batch.set(messagesRef, messageToSend.toMap());
    batch.set(
        chatRef,
        {
          'lastMessage': {
            'content': '[voice]',
            'senderId': message.senderId,
            'timestamp': FieldValue.serverTimestamp(),
            'type': MessageType.audio.name,
          },
          'updatedAt': FieldValue.serverTimestamp(),
          'unreadBy.${message.senderId}': false,
          'unreadBy.${message.receiverId}': true,
        },
        SetOptions(merge: true));
    await batch.commit();
  }

  @override
  Future<String> findOrCreateChat(String myUid, String otherUid) async {
    // Deterministic participants array (sorted) helps prevent duplicates
    final participants = [myUid, otherUid]..sort();
    final chatsRef = _firestore.collection('chats');

    // Try to find existing chat: both UIDs in participants and length==2
    final query = await chatsRef
        .where('participants', arrayContains: myUid)
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .get();

    for (final doc in query.docs) {
      final data = doc.data();
      final parts = List<String>.from(data['participants'] ?? []);
      if (parts.length == 2 && parts.contains(otherUid)) {
        return doc.id;
      }
    }

    // Not found: create new chat
    final now = FieldValue.serverTimestamp();
    final newDoc = await chatsRef.add({
      'participants': participants,
      'participantsSet': {myUid: true, otherUid: true},
      'createdAt': now,
      'updatedAt': now,
      'lastMessage': null,
      'type': 'dm',
      'unreadBy': {
        myUid: false,
        otherUid: false,
      },
    });
    return newDoc.id;
  }

  @override
  Future<void> markChatAsRead(String chatId, String userId) async {
    final chatRef = _firestore.collection('chats').doc(chatId);
    await chatRef.set({
      'unreadBy.$userId': false,
    }, SetOptions(merge: true));
  }
}
