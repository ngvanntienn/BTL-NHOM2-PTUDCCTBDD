import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/voucher_model.dart';

class VoucherService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'vouchers';

  // Create new voucher (admin/seller)
  Future<String> createVoucher(VoucherModel voucher) async {
    try {
      final docRef = await _firestore
          .collection(_collectionPath)
          .add(voucher.toMap());
      return docRef.id;
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
      await _firestore.collection(_collectionPath).doc(voucherId).update({
        'currentUsage': FieldValue.increment(1),
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
          .update(voucher.toMap());
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
    if (voucher.type == 'PERCENTAGE') {
      discount = (totalAmount * voucher.discountPercent) / 100;
      if (voucher.maxDiscountAmount != null) {
        discount = discount.clamp(0, voucher.maxDiscountAmount!);
      }
    } else if (voucher.type == 'FIXED') {
      discount = voucher.fixedDiscount ?? 0;
    }

    return discount;
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
