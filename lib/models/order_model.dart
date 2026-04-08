import 'package:cloud_firestore/cloud_firestore.dart';

import 'cart_item_model.dart';
import 'product_model.dart';

class OrderModel {
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
    this.sellerId = '',
    this.deliveryDate,
  });

  final String id;
  final String userId;
  final String sellerId;
  final List<CartItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final String status;
  final DateTime createdAt;
  final DateTime? deliveryDate;
  final String address;
  final String phone;
  final String paymentMethod;
  final String? voucherCode;

  String get orderId => id;
  double get totalPrice => total;
  String get deliveryAddress => address;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'orderId': id,
      'userId': userId,
      'sellerId': sellerId,
      'items': items.map((CartItemModel e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'total': total,
      'totalPrice': total,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'deliveryDate': deliveryDate != null
          ? Timestamp.fromDate(deliveryDate!)
          : null,
      'address': address,
      'deliveryAddress': address,
      'phone': phone,
      'paymentMethod': paymentMethod,
      'voucherCode': voucherCode,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final List<CartItemModel> parsedItems = _parseItems(map['items']);
    final String resolvedId =
        docId ?? (map['id'] ?? map['orderId'] ?? '').toString();

    return OrderModel(
      id: resolvedId,
      userId: (map['userId'] ?? '').toString(),
      sellerId: (map['sellerId'] ?? '').toString(),
      items: parsedItems,
      subtotal: _toDouble(map['subtotal']),
      deliveryFee: _toDouble(map['deliveryFee']),
      discount: _toDouble(map['discount']),
      total: _toDouble(map['total'], fallback: _toDouble(map['totalPrice'])),
      status: (map['status'] ?? 'pending').toString(),
      createdAt: _toDate(map['createdAt']),
      deliveryDate: _toNullableDate(map['deliveryDate']),
      address: (map['address'] ?? map['deliveryAddress'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      paymentMethod: (map['paymentMethod'] ?? 'cash').toString(),
      voucherCode: map['voucherCode']?.toString(),
    );
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    String? sellerId,
    List<CartItemModel>? items,
    double? subtotal,
    double? deliveryFee,
    double? discount,
    double? total,
    String? status,
    DateTime? createdAt,
    DateTime? deliveryDate,
    String? address,
    String? phone,
    String? paymentMethod,
    String? voucherCode,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sellerId: sellerId ?? this.sellerId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      voucherCode: voucherCode ?? this.voucherCode,
    );
  }

  static List<CartItemModel> _parseItems(dynamic raw) {
    if (raw is! List) {
      return <CartItemModel>[];
    }

    return raw.whereType<Map>().map((Map<dynamic, dynamic> e) {
      final Map<String, dynamic> item = Map<String, dynamic>.from(e);
      return CartItemModel(
        product: ProductModel(
          id: (item['productId'] ?? '').toString(),
          name: (item['productName'] ?? '').toString(),
          description: '',
          price: _toDouble(item['price']),
          imageUrl: (item['imageUrl'] ?? '').toString(),
          category: (item['category'] ?? '').toString(),
        ),
        quantity: (item['quantity'] as num?)?.toInt() ?? 1,
        note: item['note']?.toString(),
      );
    }).toList();
  }

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }

  static DateTime? _toNullableDate(dynamic value) {
    if (value == null) {
      return null;
    }
    return _toDate(value);
  }
}
