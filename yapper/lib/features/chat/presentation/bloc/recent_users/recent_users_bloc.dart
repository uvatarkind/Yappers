import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/user_summary.dart';
import '../../../domain/usecases/get_recent_users.dart';

part 'recent_users_event.dart';
part 'recent_users_state.dart';

class RecentUsersBloc extends Bloc<RecentUsersEvent, RecentUsersState> {
  final GetRecentUsersUseCase getRecentUsers;
  RecentUsersBloc(this.getRecentUsers) : super(RecentUsersInitial()) {
    on<LoadRecentUsers>((event, emit) async {
      emit(RecentUsersLoading());
      final res = await getRecentUsers(limit: event.limit);
      res.fold(
        (_) => emit(const RecentUsersError('Failed to load users')),
        (users) => emit(RecentUsersLoaded(users)),
      );
    });
    on<RefreshRecentUsers>((event, emit) async {
      final res = await getRecentUsers(limit: event.limit);
      res.fold(
        (_) => emit(const RecentUsersError('Failed to load users')),
        (users) => emit(RecentUsersLoaded(users)),
      );
    });
  }
}
