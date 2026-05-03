import 'package:equatable/equatable.dart';

class AppConfigModel extends Equatable {
  final int updateIntervalSeconds;
  final double minDistanceMeters;
  final DateTime updatedAt;

  const AppConfigModel({
    required this.updateIntervalSeconds,
    required this.minDistanceMeters,
    required this.updatedAt,
  });

  factory AppConfigModel.fromMap(Map<String, dynamic> map) {
    return AppConfigModel(
      updateIntervalSeconds: map['update_interval_seconds'] ?? 300,
      minDistanceMeters: (map['min_distance_meters'] as num?)?.toDouble() ?? 10.0,
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [updateIntervalSeconds, minDistanceMeters, updatedAt];
}
