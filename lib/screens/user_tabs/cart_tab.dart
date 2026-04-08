import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/address_provider.dart';
import '../../models/cart_item_model.dart';
import 'checkout_screen.dart';

class CartTab extends StatefulWidget {
  const CartTab({super.key});

  @override
  State<CartTab> createState() => _CartTabState();
}

class _CartTabState extends State<CartTab> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final items = cart.items.values.toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Giỏ hàng', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => cart.clearCart(),
              child: const Text('Xóa tất cả', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
            ),
        ],
      ),
      body: items.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildShopHeader(),
                      const SizedBox(height: 8),
                      ...items.map((item) => _buildCartItem(cart, item)).toList(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                _buildBottomBar(cart),
              ],
            ),
    );
  }

  Widget _buildShopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: const [
          Icon(Icons.storefront_outlined, color: AppTheme.textPrimary, size: 20),
          SizedBox(width: 10),
          Text('Food Delivery App Store', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartProvider cart, CartItemModel item) {
    final isSelected = cart.isSelected(item.product.id);
    return Dismissible(
      key: Key(item.product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => cart.removeItem(item.product.id),
      background: Container(color: Colors.redAccent, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete_outline, color: Colors.white)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.dividerColor)),
        child: Row(
          children: [
            Checkbox(value: isSelected, activeColor: AppTheme.primaryColor, onChanged: (_) => cart.toggleSelection(item.product.id)),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item.product.imageUrl, width: 70, height: 70, fit: BoxFit.cover)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(currencyFormat.format(item.totalPrice * 1000), style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          _actionBtn(Icons.remove, () => cart.decrementQty(item.product.id)),
                          const SizedBox(width: 12),
                          Text('${item.quantity}'),
                          const SizedBox(width: 12),
                          _actionBtn(Icons.add, () => cart.addItem(item.product)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)), child: Icon(icon, size: 14)),
    );
  }

  Widget _buildBottomBar(CartProvider cart) {
    bool isAllSelected = cart.selectedIds.length == cart.itemCount && cart.itemCount > 0;
    return Container(
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Checkbox(value: isAllSelected, activeColor: AppTheme.primaryColor, onChanged: (v) => cart.selectAll(v ?? false)),
                const Text('Tất cả'),
                const Spacer(),
                const Text('Thanh toán:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(width: 8),
                Text(currencyFormat.format(cart.total * 1000), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              if (cart.selectedCount > 0) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
              }
            },
            child: Container(
              height: 56, width: double.infinity,
              color: cart.selectedCount > 0 ? AppTheme.primaryColor : Colors.grey,
              alignment: Alignment.center,
              child: Text('Mua hàng (${cart.selectedCount})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
      Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
      SizedBox(height: 16),
      Text('Giỏ hàng đang trống'),
    ]));
  }
}
