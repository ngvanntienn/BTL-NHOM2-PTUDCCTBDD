import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _norm(String value) => value.trim().toLowerCase();

  // Get all categories - Handle missing createdAt field
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('categories')
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      final List<CategoryModel> categories = snapshot.docs.map((doc) {
        final data = doc.data();
        data['categoryId'] = doc.id;
        return CategoryModel.fromMap(data);
      }).toList();

      // Sync product count with seller foods collection.
      final QuerySnapshot<Map<String, dynamic>> foodsSnap = await _firestore
          .collection('foods')
          .get();

      final Map<String, int> countByCategoryId = <String, int>{};
      final Map<String, int> countByCategoryName = <String, int>{};

      for (final doc in foodsSnap.docs) {
        final Map<String, dynamic> data = doc.data();
        final String categoryId = (data['categoryId'] ?? '').toString().trim();
        final String categoryName = (data['category'] ?? '').toString().trim();

        if (categoryId.isNotEmpty) {
          countByCategoryId[categoryId] =
              (countByCategoryId[categoryId] ?? 0) + 1;
        }

        if (categoryName.isNotEmpty) {
          final String key = _norm(categoryName);
          countByCategoryName[key] = (countByCategoryName[key] ?? 0) + 1;
        }
      }

      final List<CategoryModel> withCounts = categories.map((category) {
        final int byId = countByCategoryId[category.categoryId] ?? 0;
        final int byName = countByCategoryName[_norm(category.name)] ?? 0;
        final int syncedCount = byId > 0 ? byId : byName;
        return category.copyWith(foodCount: syncedCount);
      }).toList();

      // Sort by createdAt in code
      withCounts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return withCounts;
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  // Get category by ID
  Future<CategoryModel?> getCategoryById(String categoryId) async {
    try {
      final doc = await _firestore
          .collection('categories')
          .doc(categoryId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        data['categoryId'] = doc.id;
        return CategoryModel.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch category: $e');
    }
  }

  // Create category
  Future<String> createCategory(CategoryModel category) async {
    try {
      final docRef = await _firestore.collection('categories').add({
        'name': category.name,
        'imageUrl': category.imageUrl,
        'createdAt': Timestamp.fromDate(category.createdAt),
        'foodCount': category.foodCount,
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  // Update category
  Future<void> updateCategory(
    String categoryId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('categories').doc(categoryId).update(data);
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection('categories').doc(categoryId).delete();
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // Search categories
  Future<List<CategoryModel>> searchCategories(String query) async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      final allCategories = snapshot.docs.map((doc) {
        final data = doc.data();
        data['categoryId'] = doc.id;
        return CategoryModel.fromMap(data);
      }).toList();

      return allCategories
          .where(
            (category) =>
                category.name.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to search categories: $e');
    }
  }

  // Get category count - Return 0 if error
  Future<int> getCategoryCount() async {
    try {
      final snapshot = await _firestore.collection('categories').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      // Return 0 if collection doesn't exist
      return 0;
    }
  }

  // Update food count for category
  Future<void> updateFoodCount(String categoryId, int count) async {
    try {
      await _firestore.collection('categories').doc(categoryId).update({
        'foodCount': count,
      });
    } catch (e) {
      throw Exception('Failed to update food count: $e');
    }
  }
}
