part of 'recent_users_bloc.dart';

abstract class RecentUsersEvent extends Equatable {
  const RecentUsersEvent();
  @override
  List<Object?> get props => [];
}

class LoadRecentUsers extends RecentUsersEvent {
  final int limit;
  const LoadRecentUsers({this.limit = 12});
}

class RefreshRecentUsers extends RecentUsersEvent {
  final int limit;
  const RefreshRecentUsers({this.limit = 12});
}
