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
    required this.isAvailable,
    required this.stock,
    required this.createdAt,
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
  final bool isAvailable;
  final int stock;
  final DateTime createdAt;

  bool get available => isAvailable && stock > 0;

  factory FoodModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return FoodModel.fromMap(doc.id, data);
  }

  factory FoodModel.fromMap(String id, Map<String, dynamic> data) {
    final int parsedStock = _toInt(data['stock'], fallback: 1);
    final bool parsedAvailable =
        (data['isAvailable'] as bool?) ?? (data['available'] as bool?) ?? true;

    return FoodModel(
      id: id,
      name: (data['name'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      category: _resolveCategory(data),
      restaurant: (data['restaurant'] ?? '').toString(),
      price: _toDouble(data['price']),
      isTrending: data['isTrending'] == true,
      rating: _toDouble(data['rating']),
      reviewCount: _toInt(data['reviewCount']),
      isAvailable: parsedAvailable,
      stock: parsedStock,
      createdAt: _toDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'restaurant': restaurant,
      'price': price,
      'isTrending': isTrending,
      'rating': rating,
      'reviewCount': reviewCount,
      'isAvailable': isAvailable,
      'available': isAvailable,
      'stock': stock,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  FoodModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? category,
    String? restaurant,
    double? price,
    bool? isTrending,
    double? rating,
    int? reviewCount,
    bool? isAvailable,
    int? stock,
    DateTime? createdAt,
  }) {
    return FoodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      restaurant: restaurant ?? this.restaurant,
      price: price ?? this.price,
      isTrending: isTrending ?? this.isTrending,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isAvailable: isAvailable ?? this.isAvailable,
      stock: stock ?? this.stock,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String _resolveCategory(Map<String, dynamic> data) {
    final String category = (data['category'] ?? '').toString().trim();
    if (category.isNotEmpty) {
      return category;
    }
    final String categoryId = (data['categoryId'] ?? '').toString().trim();
    if (categoryId.isNotEmpty) {
      return categoryId;
    }
    return 'Khac';
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }
}
