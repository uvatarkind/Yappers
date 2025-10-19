import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yapper/features/chat/domain/usecases/get_messages_stream.dart';
import 'package:yapper/features/chat/domain/usecases/send_text_message.dart';
import 'package:yapper/features/chat/domain/usecases/send_file_message.dart';
import 'package:yapper/features/chat/domain/usecases/send_voice_message.dart';
import 'package:yapper/features/chat/presentation/bloc/chat/chat_event.dart';
import 'package:yapper/features/chat/presentation/bloc/chat/chat_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yapper/features/chat/domain/entities/message.dart';
import 'package:yapper/features/chat/domain/entities/message_type.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetMessagesStreamUseCase getMessagesStream;
  final SendTextMessageUseCase sendTextMessage;
  final SendFileMessageUseCase sendFileMessage;
  final SendVoiceMessageUseCase sendVoiceMessage;
  // ... other use cases

  StreamSubscription? _messagesSubscription;
  String? _currentChatId;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  ChatBloc({
    required this.getMessagesStream,
    required this.sendTextMessage,
    required this.sendFileMessage,
    required this.sendVoiceMessage,
  }) : super(ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<MessagesUpdated>(_onMessagesUpdated);
    on<SendTextMessage>(_onSendTextMessage);
    on<SendFileMessage>(_onSendFileMessage);
    on<SendVoiceMessage>(_onSendVoiceMessage);
  }

  void _onLoadMessages(LoadMessages event, Emitter<ChatState> emit) {
    emit(ChatLoading());
    _currentChatId = event.chatId;
    _messagesSubscription?.cancel();
    _messagesSubscription = getMessagesStream(event.chatId).listen((result) {
      result.fold(
        (failure) => emit(ChatError(failure.message)),
        (messages) => add(MessagesUpdated(messages)),
      );
    });
  }

  void _onMessagesUpdated(MessagesUpdated event, Emitter<ChatState> emit) {
    emit(ChatLoaded(event.messages));
  }

  void _onSendTextMessage(
      SendTextMessage event, Emitter<ChatState> emit) async {
    final user = _auth.currentUser;
    if (user == null) {
      emit(const ChatError('User not authenticated'));
      return;
    }

    final chatId = _currentChatId;
    if (chatId == null) {
      emit(const ChatError('No chat selected'));
      return;
    }

    final receiverId = event.receiverId;
    if (receiverId == null || receiverId.isEmpty) {
      emit(const ChatError('Receiver not specified'));
      return;
    }

    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: event.text,
      senderId: user.uid,
      receiverId: receiverId,
      type: MessageType.text,
      timestamp: DateTime.now(),
    );

    final result = await sendTextMessage(message, chatId);
    result.fold((failure) => emit(ChatError(failure.message)), (_) => null);
  }

  void _onSendFileMessage(
      SendFileMessage event, Emitter<ChatState> emit) async {
    final user = _auth.currentUser;
    if (user == null) {
      emit(const ChatError('User not authenticated'));
      return;
    }

    final chatId = _currentChatId;
    if (chatId == null) {
      emit(const ChatError('No chat selected'));
      return;
    }

    final receiverId = event.receiverId;
    if (receiverId == null || receiverId.isEmpty) {
      emit(const ChatError('Receiver not specified'));
      return;
    }

    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: '', // will be set to downloadUrl in datasource
      senderId: user.uid,
      receiverId: receiverId,
      type: event.type,
      timestamp: DateTime.now(),
    );

    final result = await sendFileMessage(message, event.file, chatId);
    result.fold((failure) => emit(ChatError(failure.message)), (_) => null);
  }

  void _onSendVoiceMessage(
      SendVoiceMessage event, Emitter<ChatState> emit) async {
    final user = _auth.currentUser;
    if (user == null) {
      emit(const ChatError('User not authenticated'));
      return;
    }

    final chatId = _currentChatId;
    if (chatId == null) {
      emit(const ChatError('No chat selected'));
      return;
    }

    final receiverId = event.receiverId;
    if (receiverId == null || receiverId.isEmpty) {
      emit(const ChatError('Receiver not specified'));
      return;
    }

    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: '', // will be set to downloadUrl in datasource
      senderId: user.uid,
      receiverId: receiverId,
      type: MessageType.audio,
      timestamp: DateTime.now(),
    );

    final result = await sendVoiceMessage(message, event.audioFile, chatId);
    result.fold((failure) => emit(ChatError(failure.message)), (_) => null);
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
