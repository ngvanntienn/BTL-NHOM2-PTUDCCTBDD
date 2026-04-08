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
import 'cart_item_model.dart';
import 'product_model.dart';

class OrderModel {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final String status; // 'pending', 'confirmed', 'shipping', 'delivered', 'cancelled'
  final DateTime createdAt;
  final String address;
  final String phone;
  final String? voucherCode;
  final String paymentMethod; // New field

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.address,
    required this.phone,
    required this.paymentMethod,
    this.voucherCode,
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
      'id': id,
      'userId': userId,
      'items': items.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'total': total,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'address': address,
      'phone': phone,
      'voucherCode': voucherCode,
      'paymentMethod': paymentMethod,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      items: (map['items'] as List?)?.map((e) => CartItemModel(
        product: ProductModel(
          id: e['productId'],
          name: e['productName'],
          description: '',
          price: (e['price'] ?? 0.0).toDouble(),
          imageUrl: e['imageUrl'] ?? '',
          category: '',
        ),
        quantity: e['quantity'] ?? 1,
        note: e['note'],
      )).toList() ?? [],
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      deliveryFee: (map['deliveryFee'] ?? 0.0).toDouble(),
      discount: (map['discount'] ?? 0.0).toDouble(),
      total: (map['total'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      voucherCode: map['voucherCode'],
      paymentMethod: map['paymentMethod'] ?? 'cash',
    );
  }
}
