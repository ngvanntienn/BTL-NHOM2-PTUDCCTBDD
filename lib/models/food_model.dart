import 'package:cloud_firestore/cloud_firestore.dart';

class FoodModel {
  final String foodId;
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  final String sellerId;
  final DateTime createdAt;

  FoodModel({
    required this.foodId,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.imageUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isAvailable = true,
    required this.sellerId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'isAvailable': isAvailable,
      'sellerId': sellerId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FoodModel.fromMap(Map<String, dynamic> map) {
    return FoodModel(
      foodId: map['foodId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      categoryId: map['categoryId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: map['reviewCount'] ?? 0,
      isAvailable: map['isAvailable'] ?? true,
      sellerId: map['sellerId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  FoodModel copyWith({
    String? foodId,
    String? name,
    String? description,
    double? price,
    String? categoryId,
    String? imageUrl,
    double? rating,
    int? reviewCount,
    bool? isAvailable,
    String? sellerId,
    DateTime? createdAt,
  }) {
    return FoodModel(
      foodId: foodId ?? this.foodId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isAvailable: isAvailable ?? this.isAvailable,
      sellerId: sellerId ?? this.sellerId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
