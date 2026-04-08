import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String email;
  final String role;
  final String phone;
  final String address;
  final DateTime createdAt;
  final bool isDisabled;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    required this.address,
    required this.createdAt,
    this.isDisabled = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
      'isDisabled': isDisabled,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final dynamic createdAtRaw = map['createdAt'];
    final DateTime createdAt = createdAtRaw is Timestamp
        ? createdAtRaw.toDate()
        : DateTime.now();

    return UserModel(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      createdAt: createdAt,
      isDisabled: map['isDisabled'] ?? false,
    );
  }

  UserModel copyWith({
    String? userId,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? address,
    DateTime? createdAt,
    bool? isDisabled,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      isDisabled: isDisabled ?? this.isDisabled,
    );
  }
}
