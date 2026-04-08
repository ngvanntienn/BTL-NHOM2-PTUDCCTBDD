import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String orderId;
  final String userId;
  final String sellerId;
  final double totalPrice;
  final String status; // pending, confirmed, preparing, shipping, delivered, cancelled
  final DateTime createdAt;
  final DateTime? deliveryDate;
  final List<String> items;
  final String deliveryAddress;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.sellerId,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.deliveryDate,
    required this.items,
    required this.deliveryAddress,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'sellerId': sellerId,
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'deliveryDate': deliveryDate != null ? Timestamp.fromDate(deliveryDate!) : null,
      'items': items,
      'deliveryAddress': deliveryAddress,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      orderId: map['orderId'] ?? '',
      userId: map['userId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      deliveryDate: map['deliveryDate'] != null
          ? (map['deliveryDate'] as Timestamp).toDate()
          : null,
      items: List<String>.from(map['items'] ?? []),
      deliveryAddress: map['deliveryAddress'] ?? '',
    );
  }

  OrderModel copyWith({
    String? orderId,
    String? userId,
    String? sellerId,
    double? totalPrice,
    String? status,
    DateTime? createdAt,
    DateTime? deliveryDate,
    List<String>? items,
    String? deliveryAddress,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      sellerId: sellerId ?? this.sellerId,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      items: items ?? this.items,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    );
  }
}
