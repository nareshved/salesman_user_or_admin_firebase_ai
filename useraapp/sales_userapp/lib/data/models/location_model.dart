import 'package:equatable/equatable.dart';

class LocationModel extends Equatable {
  final String userId;
  final String name;
  final double lat;
  final double lng;
  final String address;
  final DateTime timestamp;
  final bool active;

  const LocationModel({
    required this.userId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.address,
    required this.timestamp,
    required this.active,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'lat': lat,
      'lng': lng,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
      'active': active,
      'updatedAt': timestamp.toIso8601String(),
    };
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      address: map['address'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      active: map['active'] ?? false,
    );
  }

  @override
  List<Object?> get props => [userId, name, lat, lng, address, timestamp, active];
}
