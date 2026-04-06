import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/seller/order_model.dart';
import '../services/firestore_schema.dart';

class OrderRepository {
  OrderRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(FirestoreCollections.orders);

  CollectionReference<Map<String, dynamic>> get _foodsRef =>
      _firestore.collection(FirestoreCollections.foods);

  Stream<List<OrderModel>> streamSellerOrders(String sellerId) {
    return _ref.where('sellerId', isEqualTo: sellerId).snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      final List<OrderModel> orders = snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                OrderModel.fromDoc(doc),
          )
          .toList();
      orders.sort(
        (OrderModel a, OrderModel b) => b.createdAt.compareTo(a.createdAt),
      );
      return orders;
    });
  }

  Future<void> acceptOrder(String orderId) async {
    await _firestore.runTransaction((Transaction tx) async {
      final DocumentReference<Map<String, dynamic>> orderRef = _ref.doc(
        orderId,
      );
      final DocumentSnapshot<Map<String, dynamic>> orderSnap = await tx.get(
        orderRef,
      );

      if (!orderSnap.exists) {
        throw Exception('Don hang khong ton tai.');
      }

      final Map<String, dynamic> orderData =
          orderSnap.data() ?? <String, dynamic>{};
      final OrderStatus currentStatus = orderStatusFromString(
        (orderData['status'] ?? 'pending').toString(),
      );

      if (currentStatus != OrderStatus.pending) {
        throw Exception('Chi co the nhan don o trang thai cho xu ly.');
      }

      final List<dynamic> rawItems =
          (orderData['items'] as List<dynamic>?) ?? <dynamic>[];
      final Map<String, int> totalQuantityByFoodId = <String, int>{};

      for (final dynamic raw in rawItems) {
        if (raw is! Map) {
          continue;
        }
        final Map<String, dynamic> item = Map<String, dynamic>.from(raw);
        final String foodId = (item['foodId'] ?? '').toString();
        final int quantity = (item['quantity'] as num?)?.toInt() ?? 0;
        if (foodId.isEmpty || quantity <= 0) {
          continue;
        }
        totalQuantityByFoodId[foodId] =
            (totalQuantityByFoodId[foodId] ?? 0) + quantity;
      }

      for (final MapEntry<String, int> entry in totalQuantityByFoodId.entries) {
        final DocumentReference<Map<String, dynamic>> foodRef = _foodsRef.doc(
          entry.key,
        );
        final DocumentSnapshot<Map<String, dynamic>> foodSnap = await tx.get(
          foodRef,
        );

        if (!foodSnap.exists) {
          throw Exception('Mon an ${entry.key} khong ton tai.');
        }

        final Map<String, dynamic> foodData =
            foodSnap.data() ?? <String, dynamic>{};
        final int stock = (foodData['stock'] as num?)?.toInt() ?? 0;

        if (stock < entry.value) {
          final String foodName = (foodData['name'] ?? 'mon an').toString();
          throw Exception('Khong du ton kho cho $foodName.');
        }

        final int nextStock = stock - entry.value;
        final bool currentlyAvailable =
            (foodData['isAvailable'] as bool?) ?? true;

        tx.update(foodRef, <String, dynamic>{
          'stock': nextStock,
          'isAvailable': nextStock > 0 && currentlyAvailable,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      tx.update(orderRef, <String, dynamic>{
        'status': orderStatusToString(OrderStatus.accepted),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectOrder(String orderId) {
    return _setStatus(orderId: orderId, status: OrderStatus.rejected);
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) {
    return _setStatus(orderId: orderId, status: status);
  }

  Future<void> _setStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    await _ref.doc(orderId).update(<String, dynamic>{
      'status': orderStatusToString(status),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
