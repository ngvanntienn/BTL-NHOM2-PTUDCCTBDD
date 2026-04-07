import 'package:cloud_firestore/cloud_firestore.dart';

class FoodModel {
  const FoodModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.restaurant,
    required this.price,
    required this.isTrending,
    required this.rating,
    required this.reviewCount,
  });

  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String category;
  final String restaurant;
  final double price;
  final bool isTrending;
  final double rating;
  final int reviewCount;

  factory FoodModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return FoodModel(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      category: (data['category'] ?? 'Khác').toString(),
      restaurant: (data['restaurant'] ?? '').toString(),
      price: _toDouble(data['price']),
      isTrending: data['isTrending'] == true,
      rating: _toDouble(data['rating']),
      reviewCount: _toInt(data['reviewCount']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return 0;
  }

  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}
