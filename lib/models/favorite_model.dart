import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteModel {
  final String favoriteId;
  final String userId;
  final String foodId;
  final DateTime createdAt;

  FavoriteModel({
    required this.favoriteId,
    required this.userId,
    required this.foodId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'favoriteId': favoriteId,
      'userId': userId,
      'foodId': foodId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FavoriteModel.fromMap(Map<String, dynamic> map) {
    return FavoriteModel(
      favoriteId: map['favoriteId'] ?? '',
      userId: map['userId'] ?? '',
      foodId: map['foodId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
