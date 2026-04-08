import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteModel {
  FavoriteModel({
    required this.id,
    required this.userId,
    required this.foodId,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String foodId;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'foodId': foodId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FavoriteModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return FavoriteModel(
      id: doc.id,
      userId: (data['userId'] ?? '').toString(),
      foodId: (data['foodId'] ?? '').toString(),
      createdAt: ((data['createdAt'] as Timestamp?) ?? Timestamp.now())
          .toDate(),
    );
  }
}
