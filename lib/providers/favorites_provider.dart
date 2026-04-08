import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';

class FavoritesProvider with ChangeNotifier {
  final List<ProductModel> _favorites = [];

  List<ProductModel> get favorites => [..._favorites];

  bool isFavorite(String productId) {
    return _favorites.any((p) => p.id == productId);
  }

  Future<void> toggleFavorite(ProductModel product) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(product.id);

    if (isFavorite(product.id)) {
      _favorites.removeWhere((p) => p.id == product.id);
      await docRef.delete();
    } else {
      _favorites.add(product);
      await docRef.set(product.toMap());
    }
    notifyListeners();
  }

  Future<void> fetchFavorites() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .get();

    _favorites.clear();
    for (var doc in snap.docs) {
      _favorites.add(ProductModel.fromMap(doc.data(), doc.id));
    }
    notifyListeners();
  }
}
