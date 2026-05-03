import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/location_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/app_config_model.dart';
import '../../data/repositories/location_repository.dart';

// Events
abstract class TrackingEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class TrackingStarted extends TrackingEvent {
  final UserModel user;
  TrackingStarted(this.user);
  @override
  List<Object?> get props => [user];
}

class TrackingStopped extends TrackingEvent {
  final String userId;
  TrackingStopped(this.userId);
  @override
  List<Object?> get props => [userId];
}

class TrackingLocationUpdated extends TrackingEvent {
  final LocationModel location;
  TrackingLocationUpdated(this.location);
  @override
  List<Object?> get props => [location];
}

class TrackingConfigUpdated extends TrackingEvent {
  final AppConfigModel config;
  TrackingConfigUpdated(this.config);
  @override
  List<Object?> get props => [config];
}

// States
abstract class TrackingState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TrackingInitial extends TrackingState {}

class TrackingActive extends TrackingState {
  final LocationModel? lastLocation;
  final AppConfigModel config;
  TrackingActive({this.lastLocation, required this.config});
  @override
  List<Object?> get props => [lastLocation, config];
}

class TrackingIdle extends TrackingState {
  final AppConfigModel config;
  TrackingIdle(this.config);
  @override
  List<Object?> get props => [config];
}

// Bloc
class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  final LocationRepository locationRepository;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _configSubscription;
  StreamSubscription? _statusSubscription;
  AppConfigModel _currentConfig = AppConfigModel(
    updateIntervalSeconds: 300,
    minDistanceMeters: 10.0,
    updatedAt: DateTime.now(),
  );

  TrackingBloc({required this.locationRepository}) : super(TrackingInitial()) {
    _configSubscription = locationRepository.listenToAppConfig().listen((config) {
      _currentConfig = config;
      add(TrackingConfigUpdated(config));
    });

    on<TrackingConfigUpdated>((event, emit) {
      if (state is TrackingActive) {
        emit(TrackingActive(
          lastLocation: (state as TrackingActive).lastLocation,
          config: event.config,
        ));
      } else {
        emit(TrackingIdle(event.config));
      }
    });

    on<TrackingStarted>((event, emit) async {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      emit(TrackingActive(config: _currentConfig));
      
      // Listen for status changes (Admin disabling account)
      _statusSubscription?.cancel();
      _statusSubscription = locationRepository.listenToUserStatus(event.user.uid).listen((status) {
        if (status == 'disabled') {
          add(TrackingStopped(event.user.uid));
        }
      });

      await locationRepository.updateUserStatus(event.user.uid, 'tracking');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', event.user.uid);
      await prefs.setString('userName', event.user.name);

      final service = FlutterBackgroundService();
      if (!(await service.isRunning())) {
        await service.startService();
      }

      service.on('on_location_update').listen((data) {
        if (data != null) {
          final location = LocationModel.fromMap(data);
          add(TrackingLocationUpdated(location));
        }
      });

      _locationSubscription?.cancel();
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: _currentConfig.minDistanceMeters.toInt(),
        ),
      ).listen((position) async {
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
        } catch (e) {
          // Fallback to coordinates
        }

        final location = LocationModel(
          userId: event.user.uid,
          name: event.user.name,
          lat: position.latitude,
          lng: position.longitude,
          address: address,
          timestamp: DateTime.now(),
          active: true,
        );

        add(TrackingLocationUpdated(location));
      });
    });

    on<TrackingLocationUpdated>((event, emit) async {
      if (state is TrackingActive) {
        // Sync to Firestore for real-time visibility in Admin
        await locationRepository.updateActiveLocation(event.location);
        // Also save to history
        await locationRepository.saveLocationHistory(event.location);
        
        emit(TrackingActive(lastLocation: event.location, config: _currentConfig));
      }
    });

    on<TrackingStopped>((event, emit) async {
      _locationSubscription?.cancel();
      _statusSubscription?.cancel();
      FlutterBackgroundService().invoke("stopService");
      // Only update to idle if NOT disabled (if disabled, we want it to stay disabled)
      final currentStatus = await locationRepository.listenToUserStatus(event.userId).first;
      if (currentStatus != 'disabled') {
        await locationRepository.updateUserStatus(event.userId, 'idle');
      }
      emit(TrackingIdle(_currentConfig));
    });
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    _configSubscription?.cancel();
    _statusSubscription?.cancel();
    return super.close();
  }
}
