import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/location_model.dart';
import '../models/user_model.dart';
import '../models/app_config_model.dart';

class AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Get all salesmen
  Stream<List<UserModel>> getSalesmen() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'salesman')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap({...doc.data(), 'uid': doc.id}))
            .toList());
  }

  // Get active locations for all salesmen
  Stream<List<LocationModel>> getActiveLocations() {
    return _firestore.collection('active_locations').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => LocationModel.fromMap(doc.data())).toList();
    });
  }

  // Get location history for a specific salesman and date
  Future<List<LocationModel>> getLocationHistory(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final snapshot = await _firestore
        .collection('locations')
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('timestamp', isLessThanOrEqualTo: endOfDay.toIso8601String())
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => LocationModel.fromMap(doc.data())).toList();
  }

  // Get current app config
  Stream<AppConfigModel> getAppConfig() {
    return _firestore
        .collection('settings')
        .doc('app_config')
        .snapshots()
        .map((doc) => AppConfigModel.fromMap(doc.data() ?? {}));
  }

  // Update app config
  Future<void> updateAppConfig(AppConfigModel config) async {
    await _firestore.collection('settings').doc('app_config').set({
      'update_interval_seconds': config.updateIntervalSeconds,
      'min_distance_meters': config.minDistanceMeters,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Create a new salesman (pre-profile)
  Future<void> addSalesman({required String email, required String name}) async {
    // We check if user already exists
    final existing = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    
    if (existing.docs.isNotEmpty) {
      throw Exception('A user with this email already exists.');
    }

    final docRef = _firestore.collection('users').doc();
    await docRef.set({
      'uid': docRef.id,
      'email': email,
      'name': name,
      'role': 'salesman',
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // Delete a salesman (Firestore record)
  Future<void> deleteSalesman(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
    await _firestore.collection('active_locations').doc(uid).delete();
  }

  // Update salesman status (e.g., active/idle/disabled)
  Future<void> updateSalesmanStatus(String uid, String status) async {
    await _firestore.collection('users').doc(uid).update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Update salesman name
  Future<void> updateSalesmanName(String uid, String newName) async {
    await _firestore.collection('users').doc(uid).update({
      'name': newName,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    
    // Also update name in active_locations if they are currently tracking
    final activeDoc = await _firestore.collection('active_locations').doc(uid).get();
    if (activeDoc.exists) {
      await _firestore.collection('active_locations').doc(uid).update({
        'name': newName,
      });
    }
  }
}
