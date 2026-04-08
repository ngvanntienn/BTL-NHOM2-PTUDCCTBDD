import 'package:cloud_firestore/cloud_firestore.dart';

class VoucherModel {
  final String id;
  final String code;
  final String description;
  final double discountPercent;
  final double? maxDiscountAmount;
  final double minOrderAmount;
  final int usageLimit;
  final int currentUsage;
  final DateTime expiryDate;
  final bool isActive;
  final String createdBy; // admin or seller ID
  final DateTime createdAt;
  final List<String> applicableCategories; // empty = tất cả categories
  final String type; // 'PERCENTAGE' or 'FIXED'
  final double? fixedDiscount;

  VoucherModel({
    required this.id,
    required this.code,
    required this.description,
    required this.discountPercent,
    this.maxDiscountAmount,
    required this.minOrderAmount,
    required this.usageLimit,
    required this.currentUsage,
    required this.expiryDate,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    required this.applicableCategories,
    required this.type,
    this.fixedDiscount,
  });

  bool get isExpired => DateTime.now().isAfter(expiryDate);
  bool get isUsedUp => currentUsage >= usageLimit;
  bool get canUse => isActive && !isExpired && !isUsedUp;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
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
      'type': type,
      'fixedDiscount': fixedDiscount,
    };
  }

  static VoucherModel fromMap(String id, Map<String, dynamic> map) {
    return VoucherModel(
      id: id,
      code: map['code'] ?? '',
      description: map['description'] ?? '',
      discountPercent: (map['discountPercent'] ?? 0).toDouble(),
      maxDiscountAmount: map['maxDiscountAmount']?.toDouble(),
      minOrderAmount: (map['minOrderAmount'] ?? 0).toDouble(),
      usageLimit: map['usageLimit'] ?? 0,
      currentUsage: map['currentUsage'] ?? 0,
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      applicableCategories: List<String>.from(
        map['applicableCategories'] ?? [],
      ),
      type: map['type'] ?? 'PERCENTAGE',
      fixedDiscount: map['fixedDiscount']?.toDouble(),
    );
  }

  VoucherModel copyWith({
    String? id,
    String? code,
    String? description,
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
  }) {
    return VoucherModel(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
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
    );
  }
}
