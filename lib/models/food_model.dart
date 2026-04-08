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
  final String id;
  final String name;
  final String category;
  final double price;
  final String description;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final bool available;
  final DateTime createdAt;

  FoodModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.available,
    required this.createdAt,
  });

  // ┌─ Convert model → Firestore document
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'available': available,
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
=======
  // ┌─ Create model từ Firestore document
  factory FoodModel.fromMap(String id, Map<String, dynamic> map) {
    return FoodModel(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? 'Other',
      price: (map['price'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      available: map['available'] ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // ┌─ Copy with changes
  FoodModel copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    String? description,
    String? imageUrl,
    double? rating,
    int? reviewCount,
    bool? available,
    DateTime? createdAt,
  }) {
    return FoodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      available: available ?? this.available,
      createdAt: createdAt ?? this.createdAt,
    );
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
