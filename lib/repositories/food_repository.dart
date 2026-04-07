import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/seller/food_model.dart';
import '../services/firestore_schema.dart';

class FoodRepository {
  FoodRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(FirestoreCollections.foods);

  Stream<List<FoodModel>> streamSellerFoods(String sellerId) {
    return _ref.where('sellerId', isEqualTo: sellerId).snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      final List<FoodModel> foods = snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                FoodModel.fromDoc(doc),
          )
          .toList();
      foods.sort(
        (FoodModel a, FoodModel b) => b.createdAt.compareTo(a.createdAt),
      );
      return foods;
    });
  }

  Stream<List<FoodModel>> streamAvailableFoods() {
    return _ref.where('isAvailable', isEqualTo: true).snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      final List<FoodModel> foods = snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                FoodModel.fromDoc(doc),
          )
          .where((FoodModel e) => e.stock > 0)
          .toList();
      foods.sort(
        (FoodModel a, FoodModel b) => b.createdAt.compareTo(a.createdAt),
      );
      return foods;
    });
  }

  Future<void> addFood(FoodModel food) async {
    final DocumentReference<Map<String, dynamic>> doc = _ref.doc();
    await doc.set(<String, dynamic>{
      ...food.copyWith(id: doc.id).toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isAvailable': food.stock > 0 && food.isAvailable,
    });
  }

  Future<void> updateFood(FoodModel food) async {
    await _ref.doc(food.id).update(<String, dynamic>{
      ...food.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isAvailable': food.stock > 0 && food.isAvailable,
    });
  }

  Future<void> deleteFood(String foodId) async {
    await _ref.doc(foodId).delete();
  }

  Future<void> setAvailability({
    required String foodId,
    required bool isAvailable,
    required int stock,
  }) async {
    await _ref.doc(foodId).update(<String, dynamic>{
      'isAvailable': stock > 0 && isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setStock({required String foodId, required int stock}) async {
    await _ref.doc(foodId).update(<String, dynamic>{
      'stock': stock,
      'isAvailable': stock > 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
