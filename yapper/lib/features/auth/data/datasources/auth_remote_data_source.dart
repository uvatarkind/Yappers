import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmailAndPassword(String email, String password);
  Future<UserModel> signUpWithEmailAndPassword(
      String email, String password, String name);
  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl(this._firebaseAuth, this._firestore);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  Future<void> _ensureUserDocument(UserModel model) async {
    final userDoc = _usersCollection.doc(model.uid);
    final snapshot = await userDoc.get();
    final payload = model.toFirestore();
    if (snapshot.exists) {
      await userDoc.set(payload, SetOptions(merge: true));
    } else {
      await userDoc.set({
        ...payload,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<UserModel> _buildModelFromFirebaseUser(
      firebase.User firebaseUser) async {
    final doc = await _usersCollection.doc(firebaseUser.uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc, firebaseUser.uid);
    }
    final newModel = UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      name: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      isOnline: true,
      lastSeen: DateTime.now(),
    );
    await _ensureUserDocument(newModel);
    return newModel;
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      final user = userCredential.user;
      if (user == null) {
        throw Exception('User not found.');
      }
      final model = await _buildModelFromFirebaseUser(user);
      await _usersCollection.doc(model.uid).update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      return model;
    } on firebase.FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      final user = userCredential.user;
      if (user == null) {
        throw Exception('User could not be created.');
      }
      await user.updateDisplayName(name);
      final model = UserModel(
        uid: user.uid,
        email: user.email,
        name: name,
        photoUrl: user.photoURL,
        isOnline: true,
        lastSeen: DateTime.now(),
      );
      await _ensureUserDocument(model);
      return model;
    } on firebase.FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  @override
  Future<void> signOut() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      await _usersCollection.doc(currentUser.uid).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
    await _firebaseAuth.signOut();
  }
}
