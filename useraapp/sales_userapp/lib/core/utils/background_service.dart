import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:sales_userapp/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'salesman_tracker_channel',
    'Salesman Tracker',
    description: 'This channel is used for tracking locations in background.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'salesman_tracker_channel',
      initialNotificationTitle: 'Tracking Active',
      initialNotificationContent: 'Capturing location in background',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  final prefs = await SharedPreferences.getInstance();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Dynamic interval listener
  int intervalSeconds = 300;
  firestore.collection('settings').doc('app_config').snapshots().listen((snapshot) {
    if (snapshot.exists) {
      intervalSeconds = snapshot.data()?['update_interval_seconds'] ?? 300;
    }
  });

  // Background tracking timer
  Timer.periodic(const Duration(seconds: 15), (timer) async {
    // Check if we should actually run based on dynamic interval
    // Since we can't easily change Timer.periodic frequency, we skip ticks
    if (timer.tick % (intervalSeconds ~/ 15) != 0) return;

    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        final userId = prefs.getString('userId');
        final userName = prefs.getString('userName');

        if (userId == null) return;

        try {
          // Check if user is still active/enabled
          final userDoc = await firestore.collection('users').doc(userId).get();
          if (userDoc.exists && userDoc.data()?['status'] == 'disabled') {
            service.stopSelf();
            return;
          }

          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          );

          String address = "Unknown (${position.latitude}, ${position.longitude})";
          try {
            List<Placemark> placemarks = await placemarkFromCoordinates(
              position.latitude,
              position.longitude,
            );
            if (placemarks.isNotEmpty) {
              Placemark place = placemarks[0];
              address = "${place.name}, ${place.locality}, ${place.administrativeArea}";
            }
          } catch (e) {}

          final locationData = {
            'userId': userId,
            'name': userName,
            'lat': position.latitude,
            'lng': position.longitude,
            'address': address,
            'timestamp': DateTime.now().toIso8601String(),
            'active': true,
            'updatedAt': DateTime.now().toIso8601String(),
          };

          // A) Update active location
          await firestore.collection('active_locations').doc(userId).set(locationData);

          // B) Save to history
          await firestore.collection('locations').add(locationData);

          service.invoke('on_location_update', locationData);

          service.setForegroundNotificationInfo(
            title: "Tracking Location",
            content: "Last sync: ${DateFormat('HH:mm').format(DateTime.now())} - $address",
          );
        } catch (e) {
          debugPrint("Background tracking error: $e");
        }
      }
    }
  });
}
