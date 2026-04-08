import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  accepted,
  preparing,
  shipping,
  delivered,
  rejected,
  cancelled,
}

OrderStatus orderStatusFromString(String value) {
  switch (value) {
    case 'accepted':
      return OrderStatus.accepted;
    case 'preparing':
      return OrderStatus.preparing;
    case 'shipping':
      return OrderStatus.shipping;
    case 'delivered':
      return OrderStatus.delivered;
    case 'rejected':
      return OrderStatus.rejected;
    case 'cancelled':
      return OrderStatus.cancelled;
    case 'pending':
    default:
      return OrderStatus.pending;
  }
}

String orderStatusToString(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 'pending';
    case OrderStatus.accepted:
      return 'accepted';
    case OrderStatus.preparing:
      return 'preparing';
    case OrderStatus.shipping:
      return 'shipping';
    case OrderStatus.delivered:
      return 'delivered';
    case OrderStatus.rejected:
      return 'rejected';
    case OrderStatus.cancelled:
      return 'cancelled';
  }
}

class OrderItemModel {
  OrderItemModel({
    required this.foodId,
    required this.foodName,
    required this.imageUrl,
    required this.quantity,
    required this.unitPrice,
  });

  final String foodId;
  final String foodName;
  final String imageUrl;
  final int quantity;
  final double unitPrice;

  double get lineTotal => unitPrice * quantity;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'foodId': foodId,
      'foodName': foodName,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      foodId: (map['foodId'] ?? '').toString(),
      foodName: (map['foodName'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }
}

class OrderModel {
  OrderModel({
    required this.id,
    required this.userId,
    required this.sellerId,
    required this.userName,
    required this.userPhone,
    required this.shippingAddress,
    required this.status,
    required this.totalPrice,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String sellerId;
  final String userName;
  final String userPhone;
  final String shippingAddress;
  final OrderStatus status;
  final double totalPrice;
  final List<OrderItemModel> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'sellerId': sellerId,
      'userName': userName,
      'userPhone': userPhone,
      'shippingAddress': shippingAddress,
      'status': orderStatusToString(status),
      'totalPrice': totalPrice,
      'items': items.map((OrderItemModel e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory OrderModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};

    final List<dynamic> rawItems =
        (data['items'] as List<dynamic>?) ?? <dynamic>[];
    final List<OrderItemModel> items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(OrderItemModel.fromMap)
        .toList();

    return OrderModel(
      id: doc.id,
      userId: (data['userId'] ?? '').toString(),
      sellerId: (data['sellerId'] ?? '').toString(),
      userName: (data['userName'] ?? '').toString(),
      userPhone: (data['userPhone'] ?? '').toString(),
      shippingAddress: (data['shippingAddress'] ?? '').toString(),
      status: orderStatusFromString((data['status'] ?? 'pending').toString()),
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0,
      items: items,
      createdAt: ((data['createdAt'] as Timestamp?) ?? Timestamp.now())
          .toDate(),
      updatedAt: ((data['updatedAt'] as Timestamp?) ?? Timestamp.now())
          .toDate(),
    );
  }
}
