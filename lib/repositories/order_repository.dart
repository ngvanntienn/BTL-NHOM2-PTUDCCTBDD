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
    return _ref.snapshots().asyncMap((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) async {
      final Map<String, bool> ownedFoodCache = <String, bool>{};
      final List<OrderModel> orders = <OrderModel>[];

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();
        final String orderSellerId = (data['sellerId'] ?? '').toString();

        if (orderSellerId == sellerId) {
          orders.add(OrderModel.fromDoc(doc));
          continue;
        }

        // Backward compatibility for legacy orders created without sellerId.
        if (orderSellerId.isNotEmpty) {
          continue;
        }

        final bool belongsToSeller = await _legacyOrderBelongsToSeller(
          orderData: data,
          sellerId: sellerId,
          ownedFoodCache: ownedFoodCache,
        );
        if (!belongsToSeller) {
          continue;
        }

        final Map<String, dynamic> normalized = Map<String, dynamic>.from(data)
          ..['sellerId'] = sellerId;
        orders.add(OrderModel.fromMap(doc.id, normalized));
      }

      orders.sort(
        (OrderModel a, OrderModel b) => b.createdAt.compareTo(a.createdAt),
      );
      return orders;
    });
  }

  Future<bool> _legacyOrderBelongsToSeller({
    required Map<String, dynamic> orderData,
    required String sellerId,
    required Map<String, bool> ownedFoodCache,
  }) async {
    final List<dynamic> rawItems =
        (orderData['items'] as List<dynamic>?) ?? <dynamic>[];
    for (final dynamic raw in rawItems) {
      if (raw is! Map) {
        continue;
      }
      final Map<String, dynamic> item = Map<String, dynamic>.from(raw);
      final String foodId = (item['foodId'] ?? item['productId'] ?? '')
          .toString();
      if (foodId.isEmpty) {
        continue;
      }

      if (ownedFoodCache.containsKey(foodId)) {
        if (ownedFoodCache[foodId] == true) {
          return true;
        }
        continue;
      }

      final DocumentSnapshot<Map<String, dynamic>> foodDoc = await _foodsRef
          .doc(foodId)
          .get();
      final bool isOwnedBySeller =
          (foodDoc.data()?['sellerId'] ?? '').toString() == sellerId;
      ownedFoodCache[foodId] = isOwnedBySeller;
      if (isOwnedBySeller) {
        return true;
      }
    }

    return false;
  }

  static const Map<OrderStatus, Set<OrderStatus>> _allowedTransitions =
      <OrderStatus, Set<OrderStatus>>{
        OrderStatus.pending: <OrderStatus>{
          OrderStatus.accepted,
          OrderStatus.rejected,
          OrderStatus.cancelled,
        },
        OrderStatus.accepted: <OrderStatus>{
          OrderStatus.preparing,
          OrderStatus.rejected,
        },
        OrderStatus.preparing: <OrderStatus>{
          OrderStatus.shipping,
          OrderStatus.rejected,
        },
        OrderStatus.shipping: <OrderStatus>{
          OrderStatus.delivered,
          OrderStatus.cancelled,
        },
        OrderStatus.delivered: <OrderStatus>{},
        OrderStatus.rejected: <OrderStatus>{},
        OrderStatus.cancelled: <OrderStatus>{},
      };

  Future<void> acceptOrder(String orderId) async {
    await _firestore.runTransaction((Transaction tx) async {
      final DocumentReference<Map<String, dynamic>> orderRef = _ref.doc(
        orderId,
      );
      final DocumentSnapshot<Map<String, dynamic>> orderSnap = await tx.get(
        orderRef,
      );

      if (!orderSnap.exists) {
        throw Exception('Đơn hàng không tồn tại.');
      }

      final Map<String, dynamic> orderData =
          orderSnap.data() ?? <String, dynamic>{};
      final OrderStatus currentStatus = orderStatusFromString(
        (orderData['status'] ?? 'pending').toString(),
      );

      if (currentStatus != OrderStatus.pending) {
        throw Exception('Chỉ có thể nhận đơn ở trạng thái chờ xử lý.');
      }

      final List<dynamic> rawItems =
          (orderData['items'] as List<dynamic>?) ?? <dynamic>[];
      if (rawItems.isEmpty) {
        throw Exception('Đơn hàng không có sản phẩm.');
      }
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

      if (totalQuantityByFoodId.isEmpty) {
        throw Exception('Dữ liệu sản phẩm trong đơn hàng không hợp lệ.');
      }

      for (final MapEntry<String, int> entry in totalQuantityByFoodId.entries) {
        final DocumentReference<Map<String, dynamic>> foodRef = _foodsRef.doc(
          entry.key,
        );
        final DocumentSnapshot<Map<String, dynamic>> foodSnap = await tx.get(
          foodRef,
        );

        if (!foodSnap.exists) {
          throw Exception('Mon an ${entry.key} không tồn tại.');
        }

        final Map<String, dynamic> foodData =
            foodSnap.data() ?? <String, dynamic>{};
        final int stock = (foodData['stock'] as num?)?.toInt() ?? 0;

        if (stock < entry.value) {
          final String foodName = (foodData['name'] ?? 'mon an').toString();
          throw Exception('Không đủ tồn kho cho $foodName.');
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
    return _setStatusGuarded(orderId: orderId, status: OrderStatus.rejected);
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) {
    return _setStatusGuarded(orderId: orderId, status: status);
  }

  Future<void> _setStatusGuarded({
    required String orderId,
    required OrderStatus status,
  }) async {
    await _firestore.runTransaction((Transaction tx) async {
      final DocumentReference<Map<String, dynamic>> orderRef = _ref.doc(
        orderId,
      );
      final DocumentSnapshot<Map<String, dynamic>> orderSnap = await tx.get(
        orderRef,
      );

      if (!orderSnap.exists) {
        throw Exception('Đơn hàng không tồn tại.');
      }

      final Map<String, dynamic> data = orderSnap.data() ?? <String, dynamic>{};
      final OrderStatus current = orderStatusFromString(
        (data['status'] ?? 'pending').toString(),
      );

      final Set<OrderStatus> allowed =
          _allowedTransitions[current] ?? <OrderStatus>{};
      if (!allowed.contains(status)) {
        throw Exception(
          'Không thể chuyển từ ${orderStatusToString(current)} sang ${orderStatusToString(status)}.',
        );
      }

      tx.update(orderRef, <String, dynamic>{
        'status': orderStatusToString(status),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
