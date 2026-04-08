import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';

class FavoritesProvider with ChangeNotifier {
  final List<ProductModel> _favorites = [];

  void _safeNotifyListeners() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    final isBuilding =
        phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.transientCallbacks;

    if (isBuilding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) {
          notifyListeners();
        }
      });
      return;
    }

    notifyListeners();
  }

  CollectionReference<Map<String, dynamic>> _favoritesRef(String uid) {
    return FirebaseFirestore.instance
        .collection('favorites')
        .doc(uid)
        .collection('items');
  }

  CollectionReference<Map<String, dynamic>> _legacyFavoritesRef(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites');
  }

  List<ProductModel> get favorites => [..._favorites];

  bool isFavorite(String productId) {
    return _favorites.any((p) => p.id == productId);
  }

  Future<void> toggleFavorite(ProductModel product) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = _favoritesRef(uid).doc(product.id);

    if (isFavorite(product.id)) {
      _favorites.removeWhere((p) => p.id == product.id);
      await docRef.delete();
    } else {
      _favorites.add(product);
      await docRef.set(product.toMap());
    }
    _safeNotifyListeners();
  }

  Future<void> fetchFavorites() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      clearFavorites(notify: true);
      return;
    }

    final QuerySnapshot<Map<String, dynamic>> primarySnap = await _favoritesRef(
      uid,
    ).get();
    final QuerySnapshot<Map<String, dynamic>> legacySnap =
        await _legacyFavoritesRef(uid).get();

    _favorites.clear();

    final Map<String, ProductModel> merged = <String, ProductModel>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in primarySnap.docs) {
      merged[doc.id] = ProductModel.fromMap(doc.data(), doc.id);
    }

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in legacySnap.docs) {
      merged.putIfAbsent(
        doc.id,
        () => ProductModel.fromMap(doc.data(), doc.id),
      );
    }

    _favorites.addAll(merged.values);
    _safeNotifyListeners();
  }

  void clearFavorites({bool notify = false}) {
    _favorites.clear();
    if (notify) {
      _safeNotifyListeners();
    }
  }
}
