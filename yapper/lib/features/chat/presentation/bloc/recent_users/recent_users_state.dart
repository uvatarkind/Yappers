part of 'recent_users_bloc.dart';

abstract class RecentUsersState extends Equatable {
  const RecentUsersState();
  @override
  List<Object?> get props => [];
}

class RecentUsersInitial extends RecentUsersState {}

class RecentUsersLoading extends RecentUsersState {}

class RecentUsersLoaded extends RecentUsersState {
  final List<UserSummary> users;
  const RecentUsersLoaded(this.users);

  @override
  List<Object?> get props => [users];
}

class RecentUsersError extends RecentUsersState {
  final String message;
  const RecentUsersError(this.message);
  @override
  List<Object?> get props => [message];
}
