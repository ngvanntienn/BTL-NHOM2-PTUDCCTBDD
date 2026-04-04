import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CartTab extends StatefulWidget {
  const CartTab({super.key});

  @override
  State<CartTab> createState() => _CartTabState();
}

class _CartTabState extends State<CartTab> {
  // Giỏ hàng rỗng - sẽ được điền từ Firebase sau
  final List<Map<String, dynamic>> _cartItems = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Giỏ hàng',
          style: TextStyle(
            color: Color(0xFF1C1C1E),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_cartItems.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _cartItems.clear()),
              child: const Text('Xóa tất', style: TextStyle(color: Colors.redAccent)),
            )
        ],
      ),
      body: _cartItems.isEmpty ? _buildEmptyCart() : _buildCartList(),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 60,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Giỏ hàng đang trống',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy thêm món ăn yêu thích của bạn\nvào giỏ hàng nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8E8E93),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.explore_outlined),
            label: const Text('Khám phá món ăn', style: TextStyle(fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList() {
    double subtotal = _cartItems.fold(0, (sum, item) => sum + (item['price'] ?? 0) * (item['qty'] ?? 1));
    double shipping = subtotal > 0 ? 15000 : 0;
    double total = subtotal + shipping;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _cartItems.length,
            itemBuilder: (context, index) => _buildCartItemCard(index),
          ),
        ),
        _buildOrderSummary(subtotal, shipping, total),
      ],
    );
  }

  Widget _buildCartItemCard(int index) {
    final item = _cartItems[index];
    return Dismissible(
      key: ValueKey(item['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => setState(() => _cartItems.removeAt(index)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 72,
                height: 72,
                color: const Color(0xFFF0F0F0),
                child: const Icon(Icons.fastfood, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('${item['note'] ?? ''}', style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${((item['price'] ?? 0) * (item['qty'] ?? 1)).toStringAsFixed(0)}đ',
                        style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Row(
                        children: [
                          _qtyButton(Icons.remove, () {
                            setState(() {
                              if ((item['qty'] ?? 1) > 1) item['qty']--;
                              else _cartItems.removeAt(index);
                            });
                          }),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('${item['qty'] ?? 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          _qtyButton(Icons.add, () => setState(() => item['qty'] = (item['qty'] ?? 1) + 1)),
                        ],
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildOrderSummary(double subtotal, double shipping, double total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -4))],
      ),
      child: Column(
        children: [
          // Voucher
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.local_offer_outlined, size: 18),
            label: const Text('Chọn mã giảm giá'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryColor),
              foregroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tạm tính', style: TextStyle(color: Color(0xFF8E8E93))),
              Text('${subtotal.toStringAsFixed(0)}đ', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Phí giao hàng', style: TextStyle(color: Color(0xFF8E8E93))),
              Text('${shipping.toStringAsFixed(0)}đ', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFEEEEEE)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng cộng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${total.toStringAsFixed(0)}đ',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
