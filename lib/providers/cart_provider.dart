import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/voucher_model.dart';
import '../utils/audio_helper.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItemModel> _items = {};
  final Set<String> _selectedIds = {}; // Track selected product IDs
  
  VoucherModel? _appliedVoucher;
  final double _deliveryFee = 4.50; // Mock delivery fee

  Map<String, CartItemModel> get items => {..._items};
  Set<String> get selectedIds => {..._selectedIds};

  int get itemCount => _items.length;
  int get selectedCount => _selectedIds.length;

  bool isSelected(String id) => _selectedIds.contains(id);

  // Subtotal only for selected items
  double get subtotal {
    double sum = 0;
    _items.forEach((id, item) {
      if (_selectedIds.contains(id)) sum += item.totalPrice;
    });
    return sum;
  }

  double get deliveryFee => subtotal > 0 ? _deliveryFee : 0.0;

  double get discount {
    if (_appliedVoucher == null || subtotal == 0) return 0.0;
    return _appliedVoucher!.calculateDiscount(subtotal);
  }

  double get total {
    double res = subtotal + deliveryFee - discount;
    return res < 0 ? 0 : res;
  }

  VoucherModel? get appliedVoucher => _appliedVoucher;

  void addItem(ProductModel product, {int qty = 1, String? note}) {
    if (_items.containsKey(product.id)) {
      _items.update(product.id, (existing) => CartItemModel(
        product: existing.product,
        quantity: existing.quantity + qty,
        note: note ?? existing.note,
      ));
    } else {
      _items.putIfAbsent(product.id, () => CartItemModel(
        product: product,
        quantity: qty,
        note: note,
      ));
      // Auto-select when adding new item
      _selectedIds.add(product.id);
    }
    notifyListeners();
  }

  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void selectAll(bool select) {
    if (select) {
      _selectedIds.addAll(_items.keys);
    } else {
      _selectedIds.clear();
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    _selectedIds.remove(productId);
    notifyListeners();
  }

  void decrementQty(String productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      _items.update(productId, (existing) => CartItemModel(
        product: existing.product,
        quantity: existing.quantity - 1,
        note: existing.note,
      ));
    } else {
      _items.remove(productId);
      _selectedIds.remove(productId);
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _selectedIds.clear();
    _appliedVoucher = null;
    notifyListeners();
  }

  void removeSelected() {
    for (var id in _selectedIds.toList()) {
      _items.remove(id);
    }
    _selectedIds.clear();
    notifyListeners();
  }

  Future<void> applyVoucher(String code) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('vouchers')
          .where('code', isEqualTo: code.toUpperCase())
          .where('isActive', isEqualTo: true)
          .get();

      if (snap.docs.isEmpty) throw 'Mã giảm giá không hợp lệ';

      final voucher = VoucherModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
      if (subtotal < voucher.minOrderAmount) throw 'Đơn hàng tối thiểu ${voucher.minOrderAmount}\$';

      _appliedVoucher = voucher;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  void removeVoucher() {
    _appliedVoucher = null;
    notifyListeners();
  }

  void setVoucher(VoucherModel voucher) {
    _appliedVoucher = voucher;
    notifyListeners();
  }

  Future<String> placeOrder({required String address, required String phone, required String paymentMethod}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw 'Bạn cần đăng nhập';
    if (_selectedIds.isEmpty) throw 'Hãy chọn món để đặt hàng';

    final orderRef = FirebaseFirestore.instance.collection('orders').doc();
    
    // Only order selected items
    final orderItems = _items.entries
        .where((e) => _selectedIds.contains(e.key))
        .map((e) => e.value)
        .toList();

    final order = OrderModel(
      id: orderRef.id,
      userId: user.uid,
      items: orderItems,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      total: total,
      status: 'pending',
      createdAt: DateTime.now(),
      address: address,
      phone: phone,
      paymentMethod: paymentMethod,
      voucherCode: _appliedVoucher?.code,
    );

    await orderRef.set(order.toMap());
    await AudioHelper.playSuccess();
    
    removeSelected(); // Remove only ordered items
    return orderRef.id;
  }
}
