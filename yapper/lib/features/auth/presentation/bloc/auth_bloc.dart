import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecase/login_usecase.dart';
import '../../domain/usecase/signup_usecase.dart';
import '../../domain/usecase/logout_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUsecase signInUser;
  final SignupUsecase signUpUser;
  final LogoutUsecase signOutUser;

  AuthBloc({
    required this.signInUser,
    required this.signUpUser,
    required this.signOutUser,
  }) : super(AuthInitial()) {
    on<SignInRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await signInUser(email: event.email, password: event.password);
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (user) => emit(Authenticated(user)),
      );
    });

    on<SignUpRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await signUpUser(email: event.email, password: event.password, name: event.name);
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (user) => emit(Authenticated(user)),
      );
    });

    on<SignOutRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await signOutUser();
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (_) => emit(Unauthenticated()),
      );
    });
  }
}