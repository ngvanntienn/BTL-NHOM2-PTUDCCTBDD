import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/money_utils.dart';

enum VoucherType { percentage, fixed }

class VoucherModel {
  VoucherModel({
    required this.id,
    required this.code,
    this.description = '',
    this.name = '',
    this.discountPercent = 0,
    this.maxDiscountAmount,
    this.minOrderAmount = 0,
    this.usageLimit = 0,
    this.currentUsage = 0,
    required this.expiryDate,
    this.isActive = true,
    this.createdBy = 'admin',
    required this.createdAt,
    this.applicableCategories = const <String>[],
    this.type = 'PERCENTAGE',
    this.fixedDiscount,
    this.value,
    this.maxDiscount,
  });

  final String id;
  final String code;
  final String description;
  final String name;
  final double discountPercent;
  final double? maxDiscountAmount;
  final double minOrderAmount;
  final int usageLimit;
  final int currentUsage;
  final DateTime expiryDate;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final List<String> applicableCategories;
  final String type;
  final double? fixedDiscount;

  // Legacy-compatible aliases.
  final double? value;
  final double? maxDiscount;

  bool get isExpired => DateTime.now().isAfter(expiryDate);
  bool get isUsedUp => usageLimit > 0 && currentUsage >= usageLimit;
  bool get canUse => isActive && !isExpired && !isUsedUp;

  VoucherType get voucherType {
    final String t = type.toLowerCase();
    if (t == 'fixed') {
      return VoucherType.fixed;
    }
    return VoucherType.percentage;
  }

  Map<String, dynamic> toMap() {
    final double resolvedValue =
        value ??
        (voucherType == VoucherType.fixed
            ? (fixedDiscount ?? 0)
            : discountPercent);

    return <String, dynamic>{
      'id': id,
      'code': code,
      'name': name.isEmpty ? description : name,
      'description': description,
      'discountPercent': discountPercent,
      'maxDiscountAmount': maxDiscountAmount,
      'minOrderAmount': minOrderAmount,
      'usageLimit': usageLimit,
      'currentUsage': currentUsage,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'applicableCategories': applicableCategories,
      'type': voucherType == VoucherType.fixed ? 'fixed' : 'percentage',
      'fixedDiscount': fixedDiscount,
      'value': resolvedValue,
      'maxDiscount': maxDiscount ?? maxDiscountAmount,
    };
  }

  static VoucherModel fromMap(dynamic first, dynamic second) {
    late final String id;
    late final Map<String, dynamic> map;

    if (first is String && second is Map<String, dynamic>) {
      id = first;
      map = second;
    } else if (first is Map<String, dynamic> && second is String) {
      id = second;
      map = first;
    } else {
      throw ArgumentError('Invalid arguments for VoucherModel.fromMap');
    }

    final String rawType = (map['type'] ?? 'PERCENTAGE').toString();
    final bool isFixed = rawType.toLowerCase() == 'fixed';

    final double percent = _toDouble(map['discountPercent']);
    final double fixed = _toDouble(map['fixedDiscount']);
    final double rawValue = _toDouble(map['value']);

    return VoucherModel(
      id: id,
      code: (map['code'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      discountPercent: percent > 0 ? percent : (!isFixed ? rawValue : 0),
      maxDiscountAmount: _toNullableDouble(
        map['maxDiscountAmount'] ?? map['maxDiscount'],
      ),
      minOrderAmount: _toDouble(map['minOrderAmount']),
      usageLimit: _toInt(map['usageLimit']),
      currentUsage: _toInt(map['currentUsage']),
      expiryDate: _toDate(map['expiryDate']),
      isActive: (map['isActive'] as bool?) ?? true,
      createdBy: (map['createdBy'] ?? 'admin').toString(),
      createdAt: _toDate(map['createdAt']),
      applicableCategories: List<String>.from(
        map['applicableCategories'] ?? <String>[],
      ),
      type: rawType,
      fixedDiscount: fixed > 0 ? fixed : (isFixed ? rawValue : null),
      value: rawValue,
      maxDiscount: _toNullableDouble(
        map['maxDiscount'] ?? map['maxDiscountAmount'],
      ),
    );
  }

  VoucherModel copyWith({
    String? id,
    String? code,
    String? description,
    String? name,
    double? discountPercent,
    double? maxDiscountAmount,
    double? minOrderAmount,
    int? usageLimit,
    int? currentUsage,
    DateTime? expiryDate,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    List<String>? applicableCategories,
    String? type,
    double? fixedDiscount,
    double? value,
    double? maxDiscount,
  }) {
    return VoucherModel(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      name: name ?? this.name,
      discountPercent: discountPercent ?? this.discountPercent,
      maxDiscountAmount: maxDiscountAmount ?? this.maxDiscountAmount,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      usageLimit: usageLimit ?? this.usageLimit,
      currentUsage: currentUsage ?? this.currentUsage,
      expiryDate: expiryDate ?? this.expiryDate,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      applicableCategories: applicableCategories ?? this.applicableCategories,
      type: type ?? this.type,
      fixedDiscount: fixedDiscount ?? this.fixedDiscount,
      value: value ?? this.value,
      maxDiscount: maxDiscount ?? this.maxDiscount,
    );
  }

  double calculateDiscount(double subtotal) {
    final double minOrder = MoneyUtils.normalizeVnd(minOrderAmount);
    if (subtotal < minOrder) {
      return 0;
    }

    if (voucherType == VoucherType.fixed) {
      final double fixed = MoneyUtils.normalizeVnd(fixedDiscount ?? value ?? 0);
      return fixed > subtotal ? subtotal : fixed;
    }

    final double percent = discountPercent > 0 ? discountPercent : (value ?? 0);
    double discount = (subtotal * percent) / 100;

    final double? rawCap = maxDiscountAmount ?? maxDiscount;
    final double? cap = rawCap == null ? null : MoneyUtils.normalizeVnd(rawCap);
    if (cap != null && cap > 0 && discount > cap) {
      discount = cap;
    }

    return discount;
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    final double parsed = _toDouble(value);
    return parsed == 0 ? null : parsed;
  }

  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
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
}
