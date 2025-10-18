import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repository/auth_repository_impl.dart';
import 'features/auth/domain/repository/auth_repository.dart';
import 'features/auth/domain/usecase/login_usecase.dart';
import 'features/auth/domain/usecase/signup_usecase.dart';
import 'features/auth/domain/usecase/logout_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// Chat feature imports
import 'features/chat/data/datasource/remote_datasource.dart';
import 'features/chat/data/datasource/remote_datasource_impl.dart';
import 'features/chat/data/repository/chat_repository_impl.dart';
import 'features/chat/domain/repository/chat_repository.dart';
import 'features/chat/domain/usecases/get_messages_stream.dart';
import 'features/chat/domain/usecases/send_text_message.dart';
import 'features/chat/presentation/bloc/chat/chat_bloc.dart';
import 'features/chat/presentation/bloc/chat_list/chat_list_bloc.dart';

final sl = GetIt.instance;

void init() {
  // External
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => Uuid());

  // BLoC - Auth
  sl.registerFactory(
      () => AuthBloc(signInUser: sl(), signUpUser: sl(), signOutUser: sl()));

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(sl(), sl()));
  sl.registerLazySingleton<RemoteDataSource>(
      () => FirebaseRemoteDataSource(sl(), sl(), sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remoteDataSource: sl()));
  sl.registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImpl(remoteDataSource: sl()));

  // Use Cases
  sl.registerLazySingleton(() => LoginUsecase(sl()));
  sl.registerLazySingleton(() => SignupUsecase(sl()));
  sl.registerLazySingleton(() => LogoutUsecase(sl()));
  sl.registerLazySingleton(() => GetMessagesStreamUseCase(sl()));
  sl.registerLazySingleton(() => SendTextMessageUseCase(sl()));

  // BLoC - Chat
  sl.registerFactory(
      () => ChatBloc(getMessagesStream: sl(), sendTextMessage: sl()));
  sl.registerFactory(() => ChatListBloc(auth: sl(), firestore: sl()));
}
