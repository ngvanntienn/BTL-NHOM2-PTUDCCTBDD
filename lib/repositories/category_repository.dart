import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/seller/category_model.dart';
import '../services/firestore_schema.dart';

class CategoryRepository {
  CategoryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(FirestoreCollections.categories);

  Stream<List<CategoryModel>> streamCategories() {
    return _ref.snapshots().map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final List<CategoryModel> categories = snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                CategoryModel.fromDoc(doc),
          )
          .toList();
      categories.sort(
        (CategoryModel a, CategoryModel b) => a.name.compareTo(b.name),
      );
      return categories;
    });
  }

  Future<void> ensureDefaultCategories() async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _ref.limit(1).get();
    if (snap.docs.isNotEmpty) {
      return;
    }

    final List<Map<String, dynamic>> defaults = <Map<String, dynamic>>[
      <String, dynamic>{'name': 'Cơm', 'imageUrl': ''},
      <String, dynamic>{'name': 'Bún/Phở', 'imageUrl': ''},
      <String, dynamic>{'name': 'Đồ ăn nhanh', 'imageUrl': ''},
      <String, dynamic>{'name': 'Đồ uống', 'imageUrl': ''},
      <String, dynamic>{'name': 'Tráng miệng', 'imageUrl': ''},
    ];

    final WriteBatch batch = _firestore.batch();
    for (final Map<String, dynamic> item in defaults) {
      final DocumentReference<Map<String, dynamic>> doc = _ref.doc();
      batch.set(doc, <String, dynamic>{
        ...item,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
