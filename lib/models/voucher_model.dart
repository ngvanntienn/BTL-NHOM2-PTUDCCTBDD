import 'package:cloud_firestore/cloud_firestore.dart';

enum VoucherType { percentage, fixed }

class VoucherModel {
  final String id;
  final String code;
  final String name;
  final VoucherType type;
  final double value;
  final double minOrderAmount;
  final double maxDiscount;
  final DateTime? expiryDate;
  final bool isActive;

  VoucherModel({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.value,
    this.minOrderAmount = 0.0,
    this.maxDiscount = double.infinity,
    this.expiryDate,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'type': type.name,
      'value': value,
      'minOrderAmount': minOrderAmount,
      'maxDiscount': maxDiscount,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'isActive': isActive,
    };
  }

  factory VoucherModel.fromMap(Map<String, dynamic> map, String id) {
    return VoucherModel(
      id: id,
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] == 'percentage' ? VoucherType.percentage : VoucherType.fixed,
      value: (map['value'] ?? 0.0).toDouble(),
      minOrderAmount: (map['minOrderAmount'] ?? 0.0).toDouble(),
      maxDiscount: (map['maxDiscount'] ?? double.infinity).toDouble(),
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  double calculateDiscount(double subtotal) {
    if (subtotal < minOrderAmount) return 0.0;
    if (type == VoucherType.fixed) return value;
    double discount = (subtotal * value) / 100;
    return (discount > maxDiscount) ? maxDiscount : discount;
  }
}
