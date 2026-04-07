import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String imageUrl;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CategoryModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return CategoryModel(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      createdAt: ((data['createdAt'] as Timestamp?) ?? Timestamp.now())
          .toDate(),
    );
  }
}
