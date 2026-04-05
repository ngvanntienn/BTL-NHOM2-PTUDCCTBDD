import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/seller/order_model.dart';
import '../services/firestore_schema.dart';

class OrderRepository {
  OrderRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(FirestoreCollections.orders);

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

  Future<void> acceptOrder(String orderId) {
    return _setStatus(orderId: orderId, status: OrderStatus.accepted);
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
