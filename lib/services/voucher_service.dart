import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/voucher_model.dart';

class VoucherService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'vouchers';

  Map<String, dynamic> _toFirestoreData(
    VoucherModel voucher, {
    required bool isCreate,
    String? id,
  }) {
    final String normalizedType = voucher.type.toUpperCase();
    final bool isFixed = normalizedType == 'FIXED';
    final double resolvedValue = isFixed
        ? (voucher.fixedDiscount ?? 0)
        : voucher.discountPercent;

    return <String, dynamic>{
      // Core fields
      if (id != null) 'id': id,
      'code': voucher.code.toUpperCase(),
      'name': voucher.name.isEmpty ? voucher.description : voucher.name,
      'description': voucher.description,
      'discountPercent': voucher.discountPercent,
      'maxDiscountAmount': voucher.maxDiscountAmount,
      'minOrderAmount': voucher.minOrderAmount,
      'usageLimit': voucher.usageLimit,
      'currentUsage': voucher.currentUsage,
      'expiryDate': Timestamp.fromDate(voucher.expiryDate),
      'isActive': voucher.isActive,
      'createdBy': voucher.createdBy,
      'createdAt': isCreate
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(voucher.createdAt),
      'applicableCategories': voucher.applicableCategories,
      'type': normalizedType,
      'fixedDiscount': voucher.fixedDiscount,

      // Legacy-compatible aliases (helpful when rules/old screens expect these)
      'value': resolvedValue,
      'maxDiscount': voucher.maxDiscountAmount,
    };
  }

  // Create new voucher (admin/seller)
  Future<String> createVoucher(VoucherModel voucher) async {
    try {
      final docRef = _firestore.collection(_collectionPath).doc();
      await docRef.set(
        _toFirestoreData(voucher, isCreate: true, id: docRef.id),
      );
      return docRef.id;
    } on FirebaseException catch (e) {
      throw Exception('Lỗi tạo voucher [${e.code}]: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi tạo voucher: $e');
    }
  }

  // Get all active vouchers
  Stream<List<VoucherModel>> getActiveVouchers() {
    return _firestore
        .collection(_collectionPath)
        .where('isActive', isEqualTo: true)
        .where('expiryDate', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => VoucherModel.fromMap(doc.id, doc.data()))
              .where((v) => v.canUse)
              .toList();
        });
  }

  // Get all vouchers for admin
  Stream<List<VoucherModel>> getAllVouchersForAdmin() {
    return _firestore
        .collection(_collectionPath)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => VoucherModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  // Get vouchers created by specific seller
  Stream<List<VoucherModel>> getSellerVouchers(String sellerId) {
    return _firestore
        .collection(_collectionPath)
        .where('createdBy', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
          final vouchers = snapshot.docs
              .map((doc) => VoucherModel.fromMap(doc.id, doc.data()))
              .toList();
          // Sort by createdAt in descending order (most recent first)
          vouchers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return vouchers;
        });
  }

  // Get vouchers applicable for specific category
  Stream<List<VoucherModel>> getVouchersForCategory(String category) {
    return _firestore
        .collection(_collectionPath)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => VoucherModel.fromMap(doc.id, doc.data()))
              .where((v) {
                bool appliesToCategory =
                    v.applicableCategories.isEmpty ||
                    v.applicableCategories.contains(category);
                return v.canUse && appliesToCategory;
              })
              .toList();
        });
  }

  // Search vouchers by code
  Future<VoucherModel?> searchVoucherByCode(String code) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionPath)
          .where('code', isEqualTo: code.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final voucher = VoucherModel.fromMap(
        snapshot.docs.first.id,
        snapshot.docs.first.data(),
      );
      if (voucher.canUse) return voucher;
      return null;
    } catch (e) {
      throw Exception('Lỗi tìm voucher: $e');
    }
  }

  // Apply voucher (increment usage)
  Future<void> applyVoucher(String voucherId) async {
    try {
      await _firestore.runTransaction((tx) async {
        final DocumentReference<Map<String, dynamic>> ref = _firestore
            .collection(_collectionPath)
            .doc(voucherId);
        final DocumentSnapshot<Map<String, dynamic>> snap = await tx.get(ref);

        if (!snap.exists) {
          throw Exception('Voucher không tồn tại.');
        }

        final Map<String, dynamic> data = snap.data() ?? <String, dynamic>{};
        final bool isActive = (data['isActive'] as bool?) ?? true;
        if (!isActive) {
          throw Exception('Voucher đã hết hiệu lực.');
        }

        final DateTime expiryDate = _toDate(data['expiryDate']);
        if (DateTime.now().isAfter(expiryDate)) {
          tx.update(ref, <String, dynamic>{'isActive': false});
          throw Exception('Voucher đã hết hạn.');
        }

        final int usageLimit = _toInt(data['usageLimit']);
        final int currentUsage = _toInt(data['currentUsage']);

        if (usageLimit > 0 && currentUsage >= usageLimit) {
          tx.update(ref, <String, dynamic>{'isActive': false});
          throw Exception('Voucher đã hết lượt sử dụng.');
        }

        final int nextUsage = currentUsage + 1;
        tx.update(ref, <String, dynamic>{
          'currentUsage': nextUsage,
          if (usageLimit > 0 && nextUsage >= usageLimit) 'isActive': false,
        });
      });
    } catch (e) {
      throw Exception('Lỗi áp dụng voucher: $e');
    }
  }

  // Update voucher
  Future<void> updateVoucher(String voucherId, VoucherModel voucher) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(voucherId)
          .update(_toFirestoreData(voucher, isCreate: false, id: voucherId));
    } on FirebaseException catch (e) {
      throw Exception('Lỗi cập nhật voucher [${e.code}]: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi cập nhật voucher: $e');
    }
  }

  // Delete voucher
  Future<void> deleteVoucher(String voucherId) async {
    try {
      await _firestore.collection(_collectionPath).doc(voucherId).delete();
    } catch (e) {
      throw Exception('Lỗi xóa voucher: $e');
    }
  }

  // Deactivate voucher
  Future<void> deactivateVoucher(String voucherId) async {
    try {
      await _firestore.collection(_collectionPath).doc(voucherId).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Lỗi vô hiệu hóa voucher: $e');
    }
  }

  // Calculate discount amount
  double calculateDiscount(VoucherModel voucher, double totalAmount) {
    if (!voucher.canUse || totalAmount < voucher.minOrderAmount) {
      return 0;
    }

    double discount = 0;
    final String normalizedType = voucher.type.toUpperCase();
    if (normalizedType == 'PERCENTAGE') {
      discount = (totalAmount * voucher.discountPercent) / 100;
      if (voucher.maxDiscountAmount != null) {
        discount = discount.clamp(0, voucher.maxDiscountAmount!);
      }
    } else if (normalizedType == 'FIXED') {
      discount = voucher.fixedDiscount ?? 0;
    }

    return discount;
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

  // Get top vouchers (for promotion display)
  Stream<List<VoucherModel>> getTopVouchers({int limit = 5}) {
    return _firestore
        .collection(_collectionPath)
        .where('isActive', isEqualTo: true)
        .orderBy('currentUsage', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => VoucherModel.fromMap(doc.id, doc.data()))
              .where((v) => v.canUse)
              .toList();
        });
  }
}
