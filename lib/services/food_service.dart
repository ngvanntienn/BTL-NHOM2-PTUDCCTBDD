import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_model.dart';

class FoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'foods';

  /// ┌─ Get all foods as Stream
  Stream<List<FoodModel>> getAllFoods() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FoodModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  /// ┌─ Search foods by name (case-insensitive)
  Stream<List<FoodModel>> searchFoods(String query) {
    if (query.isEmpty) {
      return getAllFoods();
    }

    final lowerQuery = query.toLowerCase();

    return _firestore.collection(_collectionName).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => FoodModel.fromMap(doc.id, doc.data()))
          .where(
            (food) =>
                food.name.toLowerCase().contains(lowerQuery) ||
                food.description.toLowerCase().contains(lowerQuery) ||
                food.category.toLowerCase().contains(lowerQuery),
          )
          .toList();
    });
  }

  /// ┌─ Filter foods by category
  Stream<List<FoodModel>> getFoodsByCategory(String category) {
    if (category.isEmpty || category == 'Tất cả') {
      return getAllFoods();
    }

    return _firestore
        .collection(_collectionName)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FoodModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  /// ┌─ Search AND filter by category
  Stream<List<FoodModel>> searchAndFilterFoods(String query, String category) {
    if (query.isEmpty && (category.isEmpty || category == 'Tất cả')) {
      return getAllFoods();
    }

    final lowerQuery = query.toLowerCase();

    return _firestore.collection(_collectionName).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => FoodModel.fromMap(doc.id, doc.data()))
          .where((food) {
            // Filter by category
            bool categoryMatch =
                category.isEmpty ||
                category == 'Tất cả' ||
                food.category == category;

            // Filter by search query
            bool searchMatch =
                query.isEmpty ||
                food.name.toLowerCase().contains(lowerQuery) ||
                food.description.toLowerCase().contains(lowerQuery);

            return categoryMatch && searchMatch;
          })
          .toList();
    });
  }

  /// ┌─ Get food by ID
  Future<FoodModel?> getFoodById(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      if (doc.exists) {
        return FoodModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting food: $e');
      return null;
    }
  }

  /// ┌─ Get all available categories
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore.collection(_collectionName).get();
      final categories = <String>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['category'] != null) {
          categories.add(data['category'] as String);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  /// ┌─ Add new food (admin only)
  Future<String?> addFood(FoodModel food) async {
    try {
      final docRef = await _firestore
          .collection(_collectionName)
          .add(food.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding food: $e');
      return null;
    }
  }

  /// ┌─ Update food
  Future<bool> updateFood(String id, FoodModel food) async {
    try {
      await _firestore.collection(_collectionName).doc(id).update(food.toMap());
      return true;
    } catch (e) {
      print('Error updating food: $e');
      return false;
    }
  }

  /// ┌─ Delete food
  Future<bool> deleteFood(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting food: $e');
      return false;
    }
  }

  /// ┌─ Get popular foods (high rating)
  Future<List<FoodModel>> getPopularFoods({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('available', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => FoodModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting popular foods: $e');
      return [];
    }
  }

  /// ┌─ Get trending foods (most reviewed)
  Future<List<FoodModel>> getTrendingFoods({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('available', isEqualTo: true)
          .orderBy('reviewCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => FoodModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting trending foods: $e');
      return [];
    }
  }

  /// ┌─ Get new foods (latest)
  Future<List<FoodModel>> getNewFoods({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('available', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => FoodModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting new foods: $e');
      return [];
    }
  }

  /// ┌─ Get recommended foods (mix of popular + trending)
  Future<List<FoodModel>> getRecommendedFoods({int limit = 15}) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('available', isEqualTo: true)
          .orderBy('rating', descending: true)
          .orderBy('reviewCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => FoodModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting recommended foods: $e');
      return [];
    }
  }

  /// ┌─ Fuzzy search (gần đúng) - Levenshtein distance
  Future<List<FoodModel>> fuzzySearchFoods(
    String query, {
    int threshold = 2,
  }) async {
    if (query.isEmpty) return [];

    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('available', isEqualTo: true)
          .get();

      final results = snapshot.docs
          .map((doc) => FoodModel.fromMap(doc.id, doc.data()))
          .where((food) {
            final distance = _levenshteinDistance(
              query.toLowerCase(),
              food.name.toLowerCase(),
            );
            return distance <= threshold;
          })
          .toList();

      // Sort by similarity distance
      results.sort((a, b) {
        final distA = _levenshteinDistance(
          query.toLowerCase(),
          a.name.toLowerCase(),
        );
        final distB = _levenshteinDistance(
          query.toLowerCase(),
          b.name.toLowerCase(),
        );
        return distA.compareTo(distB);
      });

      return results;
    } catch (e) {
      print('Error fuzzy searching: $e');
      return [];
    }
  }

  /// ┌─ Get search suggestions (autocomplete)
  Future<List<String>> getSearchSuggestions(
    String query, {
    int limit = 5,
  }) async {
    if (query.isEmpty) return [];

    try {
      final lowerQuery = query.toLowerCase();
      final snapshot = await _firestore.collection(_collectionName).get();

      final suggestions = <String>{};

      for (var doc in snapshot.docs) {
        final food = FoodModel.fromMap(doc.id, doc.data());

        // Match by name
        if (food.name.toLowerCase().startsWith(lowerQuery)) {
          suggestions.add(food.name);
        }
        // Match by category
        if (food.category.toLowerCase().startsWith(lowerQuery)) {
          suggestions.add(food.category);
        }
      }

      return suggestions.toList()
        ..sort()
        ..take(limit);
    } catch (e) {
      print('Error getting suggestions: $e');
      return [];
    }
  }

  /// ┌─ Get foods within price range
  Future<List<FoodModel>> getFoodsByPriceRange(
    double minPrice,
    double maxPrice,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('available', isEqualTo: true)
          .where('price', isGreaterThanOrEqualTo: minPrice)
          .where('price', isLessThanOrEqualTo: maxPrice)
          .get();

      return snapshot.docs
          .map((doc) => FoodModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting foods by price: $e');
      return [];
    }
  }

  /// ┌─ Get foods with minimum rating
  Future<List<FoodModel>> getFoodsByRating(double minRating) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('available', isEqualTo: true)
          .where('rating', isGreaterThanOrEqualTo: minRating)
          .orderBy('rating', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FoodModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting foods by rating: $e');
      return [];
    }
  }

  /// ┌─ Advanced search with filters
  Future<List<FoodModel>> advancedSearch({
    String query = '',
    String category = '',
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) async {
    try {
      // Start with all foods
      var snapshot = await _firestore
          .collection(_collectionName)
          .where('available', isEqualTo: true)
          .get();

      var results = snapshot.docs
          .map((doc) => FoodModel.fromMap(doc.id, doc.data()))
          .toList();

      // Filter by query
      if (query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        results = results
            .where(
              (food) =>
                  food.name.toLowerCase().contains(lowerQuery) ||
                  food.description.toLowerCase().contains(lowerQuery),
            )
            .toList();
      }

      // Filter by category
      if (category.isNotEmpty && category != 'Tất cả') {
        results = results.where((food) => food.category == category).toList();
      }

      // Filter by price range
      if (minPrice != null) {
        results = results.where((food) => food.price >= minPrice).toList();
      }
      if (maxPrice != null) {
        results = results.where((food) => food.price <= maxPrice).toList();
      }

      // Filter by rating
      if (minRating != null) {
        results = results.where((food) => food.rating >= minRating).toList();
      }

      return results;
    } catch (e) {
      print('Error advanced searching: $e');
      return [];
    }
  }

  /// ┌─ Helper: Calculate Levenshtein distance (for fuzzy search)
  int _levenshteinDistance(String s1, String s2) {
    final len1 = s1.length;
    final len2 = s2.length;
    final d = List<List<int>>.generate(
      len1 + 1,
      (i) => List<int>.filled(len2 + 1, 0),
    );

    for (int i = 0; i <= len1; i++) {
      d[i][0] = i;
    }
    for (int j = 0; j <= len2; j++) {
      d[0][j] = j;
    }

    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1, // deletion
          d[i][j - 1] + 1, // insertion
          d[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return d[len1][len2];
  }
}
