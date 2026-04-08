import 'package:cloud_firestore/cloud_firestore.dart';

class FoodReviewModel {
  const FoodReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime? createdAt;

  factory FoodReviewModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return FoodReviewModel(
      id: doc.id,
      userId: (data['userId'] ?? '').toString(),
      userName: (data['userName'] ?? '').toString(),
      rating: data['rating'] is num ? (data['rating'] as num).toDouble() : 0,
      comment: (data['comment'] ?? '').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
