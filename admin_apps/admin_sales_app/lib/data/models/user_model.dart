import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String status;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.role = 'salesman',
    this.status = 'idle',
    this.createdAt,
    this.lastActiveAt,
  });

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? status,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'salesman',
      status: map['status'] ?? 'idle',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      lastActiveAt: map['lastActiveAt'] != null ? DateTime.parse(map['lastActiveAt']) : null,
    );
  }

  @override
  List<Object?> get props => [uid, email, name, role, status, createdAt, lastActiveAt];
}
