import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String categoryId;
  final String name;
  final String imageUrl;
  final DateTime createdAt;
  final int foodCount;

  CategoryModel({
    required this.categoryId,
    required this.name,
    required this.imageUrl,
    required this.createdAt,
    this.foodCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'name': name,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'foodCount': foodCount,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    final dynamic createdAtRaw = map['createdAt'];
    final DateTime createdAt = createdAtRaw is Timestamp
        ? createdAtRaw.toDate()
        : DateTime.now();

    return CategoryModel(
      categoryId: map['categoryId'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      createdAt: createdAt,
      foodCount: map['foodCount'] ?? 0,
    );
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['categoryId'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      foodCount: json['foodCount'] ?? 0,
    );
  }

  CategoryModel copyWith({
    String? categoryId,
    String? name,
    String? imageUrl,
    DateTime? createdAt,
    int? foodCount,
  }) {
    return CategoryModel(
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      foodCount: foodCount ?? this.foodCount,
    );
  }
}
