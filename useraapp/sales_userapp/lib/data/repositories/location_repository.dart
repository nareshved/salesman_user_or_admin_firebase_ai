import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/location_model.dart';
import '../models/app_config_model.dart';

class LocationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<AppConfigModel> listenToAppConfig() {
    return _firestore
        .collection('settings')
        .doc('app_config')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return AppConfigModel.fromMap(snapshot.data() as Map<String, dynamic>);
      }
      return AppConfigModel(
        updateIntervalSeconds: 300,
        minDistanceMeters: 10.0,
        updatedAt: DateTime.now(),
      );
    });
  }

  Future<void> updateActiveLocation(LocationModel location) async {
    await _firestore
        .collection('active_locations')
        .doc(location.userId)
        .set(location.toMap());
  }

  Future<void> saveLocationHistory(LocationModel location) async {
    await _firestore.collection('locations').add(location.toMap());
  }

  Future<void> updateUserStatus(String userId, String status) async {
    await _firestore.collection('users').doc(userId).update({
      'status': status,
      'lastActiveAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<String> listenToUserStatus(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data()?['status'] as String? ?? 'idle');
  }
}
