import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yapper/features/chat/data/models/message_model.dart';
import 'package:yapper/features/chat/data/datasource/remote_datasource.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:yapper/features/chat/domain/entities/message_type.dart';

class FirebaseRemoteDataSource implements RemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Uuid _uuid;

  FirebaseRemoteDataSource(this._firestore, this._storage, this._uuid);

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
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());
  }

  // Upload a file and send the message
  @override
  Future<void> sendFileMessage(
    MessageModel message, File file, String chatId) async {
    // 1. Upload file to Firebase Storage
    String fileName = _uuid.v4();
    Reference ref =
        _storage.ref().child('chat_files').child(chatId).child(fileName);
    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

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
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageToSend.toMap());
  }

  // Upload a voice file and send the message
  @override
  Future<void> sendVoiceMessage(
      MessageModel message, File file, String chatId) async {
    // 1. Upload voice file to Firebase Storage
    String fileName = _uuid.v4();
    Reference ref =
        _storage.ref().child('chat_voice').child(chatId).child(fileName);
    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

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
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageToSend.toMap());
  }
}
