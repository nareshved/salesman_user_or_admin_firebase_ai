import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get user => _auth.authStateChanges();

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // 1. Check if an admin pre-created a profile for this email
      final existingDocs = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      UserModel userModel;

      if (existingDocs.docs.isNotEmpty) {
        // 2. Claim existing profile
        final existingDoc = existingDocs.docs.first;
        final existingData = existingDoc.data();
        
        userModel = UserModel(
          uid: user!.uid,
          email: email,
          name: name,
          role: existingData['role'] ?? 'salesman',
          status: 'idle', // Mark as active/idle now
          createdAt: existingData['createdAt'] != null 
              ? DateTime.parse(existingData['createdAt']) 
              : DateTime.now(),
          lastActiveAt: DateTime.now(),
        );

        // Delete the temporary pre-profile doc if it had a different ID
        if (existingDoc.id != user.uid) {
          await _firestore.collection('users').doc(existingDoc.id).delete();
        }
      } else {
        // 3. New profile
        userModel = UserModel(
          uid: user!.uid,
          email: email,
          name: name,
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        );
      }

      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
      return userModel;
    } catch (e) {
      rethrow;
    }
  }

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

      final userModel = UserModel.fromMap(doc.data() as Map<String, dynamic>);
      
      if (userModel.role != 'salesman') {
        await _auth.signOut();
        throw Exception('Access denied. Salesman role required.');
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
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    }
    return null;
  }
}
