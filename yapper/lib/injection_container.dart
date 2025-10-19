import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'features/storage/supabase_storage_service.dart';
import 'core/supabase_config.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:uuid/uuid.dart';
import 'package:yapper/features/profile/presentation/bloc/theme/theme_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/network_info.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
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
import 'features/chat/domain/usecases/send_file_message.dart';
import 'features/chat/domain/usecases/send_voice_message.dart';
import 'features/chat/domain/usecases/create_or_get_chat.dart';
import 'features/chat/presentation/bloc/chat/chat_bloc.dart';
import 'features/chat/presentation/bloc/chat_list/chat_list_bloc.dart';
import 'features/chat/data/datasource/user_remote_data_source.dart';
import 'features/chat/data/repository/user_repository_impl.dart';
import 'features/chat/domain/repository/user_repository.dart';
import 'features/chat/domain/usecases/get_recent_users.dart';
import 'features/chat/presentation/bloc/recent_users/recent_users_bloc.dart';

// Profile feature imports
import 'features/profile/data/datasources/profile_remote_data_source.dart';
import 'features/profile/data/datasources/user_profile_remote_data_source.dart';
import 'features/profile/data/repositories/user_profile_repository_impl.dart';
import 'features/profile/domain/repository/profile_repository.dart';
import 'features/profile/domain/usecases/get_user_profile.dart';
import 'features/profile/domain/usecases/update_user_profile.dart';
import 'features/profile/domain/usecases/upload_profile_picture.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // --- Features ---

  // Auth
  sl.registerFactory(
      () => AuthBloc(signInUser: sl(), signUpUser: sl(), signOutUser: sl()));
  sl.registerLazySingleton(() => LoginUsecase(sl()));
  sl.registerLazySingleton(() => SignupUsecase(sl()));
  sl.registerLazySingleton(() => LogoutUsecase(sl()));
  sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()));
  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(sl(), sl()));
  sl.registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(sl()));

  // Chat
  sl.registerFactory(() => ChatBloc(
        getMessagesStream: sl(),
        sendTextMessage: sl(),
        sendFileMessage: sl(),
        sendVoiceMessage: sl(),
      ));
  sl.registerFactory(() => ChatListBloc(auth: sl(), firestore: sl()));
  sl.registerLazySingleton(() => GetMessagesStreamUseCase(sl()));
  sl.registerLazySingleton(() => SendTextMessageUseCase(sl()));
  sl.registerLazySingleton(() => SendFileMessageUseCase(sl()));
  sl.registerLazySingleton(() => SendVoiceMessageUseCase(sl()));
  sl.registerLazySingleton(() => CreateOrGetChatUseCase(sl()));
  sl.registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImpl(remoteDataSource: sl()));
  sl.registerLazySingleton<RemoteDataSource>(
      () => SupabaseRemoteDataSource(sl(), sl(), sl()));

  // Recent users (clean architecture)
  sl.registerLazySingleton<UserRemoteDataSource>(
      () => UserRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<UserRepository>(() => UserRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetRecentUsersUseCase(sl()));
  sl.registerFactory(() => RecentUsersBloc(sl()));

  // Profile
  sl.registerFactory(() => ProfileBloc(
        getUserProfile: sl(),
        updateUserProfile: sl(),
        uploadProfilePicture: sl(),
      ));
  sl.registerLazySingleton(() => GetUserProfile(sl()));
  sl.registerLazySingleton(() => UpdateUserProfile(sl()));
  sl.registerLazySingleton(() => UploadProfilePicture(sl()));
  sl.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(remoteDataSource: sl()));
  sl.registerLazySingleton<ProfileRemoteDataSource>(
      () => ProfileRemoteDataSourceImpl(firestore: sl(), storage: sl()));
  sl.registerLazySingleton<UserProfileRemoteDataSource>(
      () => UserProfileRemoteDataSourceImpl(firestore: sl(), storage: sl()));
  sl.registerFactory(() => ThemeBloc());

  // --- Core ---
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // --- External ---
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  // Supabase Storage service (uses global client initialized in main)
  sl.registerLazySingleton(
      () => SupabaseStorageService(bucket: supabaseBucketName));
  sl.registerLazySingleton(() => Uuid());
  sl.registerLazySingletonAsync<SharedPreferences>(
      () async => await SharedPreferences.getInstance());

  // InternetConnectionChecker requires async creation on some platforms
  sl.registerLazySingletonAsync<InternetConnectionChecker>(
      () async => await InternetConnectionChecker.createInstance());

  // ✅ Wait for async singletons to be ready
  await sl.isReady<InternetConnectionChecker>();
  await sl.isReady<SharedPreferences>();
}
