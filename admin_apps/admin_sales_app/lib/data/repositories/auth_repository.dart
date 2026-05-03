import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get user => _auth.authStateChanges();

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      DocumentSnapshot doc = await _firestore.collection('users').doc(result.user!.uid).get();
      
      if (!doc.exists) {
        await _auth.signOut();
        throw Exception('User record not found.');
      }

      final userModel = UserModel.fromMap({
        ...doc.data() as Map<String, dynamic>,
        'uid': doc.id,
      });
      
      if (userModel.role != 'admin') {
        await _auth.signOut();
        throw Exception('Access denied. Admin role required.');
      }

      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getCurrentUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromMap({
          ...doc.data() as Map<String, dynamic>,
          'uid': doc.id,
        });
      }
    }
    return null;
  }
}
