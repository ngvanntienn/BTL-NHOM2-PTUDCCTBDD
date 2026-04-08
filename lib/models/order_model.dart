import 'package:cloud_firestore/cloud_firestore.dart';
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
