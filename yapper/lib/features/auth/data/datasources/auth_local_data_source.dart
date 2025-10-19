import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserEntity user);
  Future<UserEntity?> getCachedUser();
  Future<void> clearCachedUser();
  Future<void> setLoggedIn(bool value);
  Future<bool> isLoggedIn();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const _kLoggedIn = 'logged_in';
  static const _kUid = 'user_uid';
  static const _kEmail = 'user_email';
  static const _kName = 'user_name';
  static const _kPhoto = 'user_photo';

  final SharedPreferences prefs;

  AuthLocalDataSourceImpl(this.prefs);

  @override
  Future<void> cacheUser(UserEntity user) async {
    await prefs.setString(_kUid, user.uid);
    await prefs.setString(_kEmail, user.email);
    await prefs.setString(_kName, user.name);
    await prefs.setString(_kPhoto, user.photoUrl ?? '');
    await setLoggedIn(true);
  }

  @override
  Future<UserEntity?> getCachedUser() async {
    final logged = prefs.getBool(_kLoggedIn) ?? false;
    if (!logged) return null;
    final uid = prefs.getString(_kUid);
    final email = prefs.getString(_kEmail);
    final name = prefs.getString(_kName);
    if (uid == null || uid.isEmpty || email == null || name == null) {
      return null;
    }
    return UserEntity(
      uid: uid,
      email: email,
      name: name,
      photoUrl: prefs.getString(_kPhoto),
      isOnline: true,
      lastSeen: DateTime.now(),
    );
  }

  @override
  Future<void> clearCachedUser() async {
    await prefs.remove(_kUid);
    await prefs.remove(_kEmail);
    await prefs.remove(_kName);
    await prefs.remove(_kPhoto);
    await setLoggedIn(false);
  }

  @override
  Future<void> setLoggedIn(bool value) async {
    await prefs.setBool(_kLoggedIn, value);
  }

  @override
  Future<bool> isLoggedIn() async {
    return prefs.getBool(_kLoggedIn) ?? false;
  }
}
