import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  ReviewModel({
    required this.id,
    required this.userId,
    required this.foodId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String foodId;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'foodId': foodId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ReviewModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return ReviewModel(
      id: doc.id,
      userId: (data['userId'] ?? '').toString(),
      foodId: (data['foodId'] ?? '').toString(),
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      comment: (data['comment'] ?? '').toString(),
      createdAt: ((data['createdAt'] as Timestamp?) ?? Timestamp.now())
          .toDate(),
    );
  }
}
