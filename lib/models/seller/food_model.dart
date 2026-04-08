import 'package:cloud_firestore/cloud_firestore.dart';

class FoodModel {
  FoodModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    required this.sellerId,
    required this.rating,
    required this.isAvailable,
    required this.stock,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String categoryId;
  final String sellerId;
  final double rating;
  final bool isAvailable;
  final int stock;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOutOfStock => stock <= 0;

  FoodModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? categoryId,
    String? sellerId,
    double? rating,
    bool? isAvailable,
    int? stock,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      sellerId: sellerId ?? this.sellerId,
      rating: rating ?? this.rating,
      isAvailable: isAvailable ?? this.isAvailable,
      stock: stock ?? this.stock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'sellerId': sellerId,
      'rating': rating,
      'isAvailable': isAvailable,
      'stock': stock,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory FoodModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};

    final Timestamp createdTs =
        (data['createdAt'] as Timestamp?) ?? Timestamp.now();
    final Timestamp updatedTs =
        (data['updatedAt'] as Timestamp?) ?? Timestamp.now();
    final int stock = (data['stock'] as num?)?.toInt() ?? 0;

    return FoodModel(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      price: (data['price'] as num?)?.toDouble() ?? 0,
      imageUrl: (data['imageUrl'] ?? '').toString(),
      categoryId: (data['categoryId'] ?? '').toString(),
      sellerId: (data['sellerId'] ?? '').toString(),
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      isAvailable: (data['isAvailable'] as bool?) ?? stock > 0,
      stock: stock,
      createdAt: createdTs.toDate(),
      updatedAt: updatedTs.toDate(),
    );
  }
}
