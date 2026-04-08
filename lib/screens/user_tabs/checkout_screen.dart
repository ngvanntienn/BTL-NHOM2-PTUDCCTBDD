import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/voucher_model.dart';
import '../../utils/money_utils.dart';
import 'address_screen.dart';
import 'payment_method_screen.dart';
import 'mock_payment_screen.dart';
import 'voucher_screen.dart';
import 'order_detail_screen.dart'; // Add this

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  String _paymentMethod = 'cash';
  bool _isProcessing = false;

  final Map<String, Map<String, dynamic>> _methodsData = {
    'banking': {
      'label': 'Chuyển khoản',
      'icon': Icons.account_balance_outlined,
      'color': Colors.blue,
    },
    'cash': {
      'label': 'Tiền mặt (COD)',
      'icon': Icons.currency_exchange_rounded,
      'color': Colors.green,
    },
  };

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final addrProvider = Provider.of<AddressProvider>(context);
    final items = cart.items.entries
        .where((e) => cart.isSelected(e.key))
        .map((e) => e.value)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Xác nhận đặt hàng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildAddressSection(addrProvider),
                const SizedBox(height: 8),
                _buildProductList(items),
                const SizedBox(height: 8),
                _buildVoucherSection(cart),
                const SizedBox(height: 8),
                _buildPaymentMethodSection(),
                const SizedBox(height: 8),
                _buildSummary(cart),
                const SizedBox(height: 120),
              ],
            ),
          ),
          _buildFooter(cart, addrProvider),
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(AddressProvider provider) {
    final addr = provider.selectedAddress;
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.location_on, color: AppTheme.primaryColor, size: 18),
              SizedBox(width: 8),
              Text(
                'Thông tin người nhận',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddressScreen(isPicker: true),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: addr == null
                      ? const Text(
                          'Vui lòng chọn địa chỉ nhận hàng',
                          style: TextStyle(color: Colors.redAccent),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${addr.receiverName} | ${addr.phoneNumber}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              addr.detail,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildDivider(),
        ],
      ),
    );
  }

  Widget _buildProductList(List<dynamic> items) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đơn hàng',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          ...items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.product.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        'x${item.quantity}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        MoneyUtils.formatVnd(currencyFormat, item.totalPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildVoucherSection(CartProvider cart) {
    final bool hasVoucher = cart.appliedVoucher != null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          InkWell(
            onTap: () => _showVoucherPicker(cart),
            child: Row(
              children: [
                const Icon(
                  Icons.local_offer_outlined,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Voucher từ Shop',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  hasVoucher ? cart.appliedVoucher!.code : 'Chọn Voucher',
                  style: TextStyle(
                    color: hasVoucher ? AppTheme.primaryColor : Colors.grey,
                    fontSize: 13,
                    fontWeight: hasVoucher
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ],
            ),
          ),
          if (hasVoucher)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: cart.removeVoucher,
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Hủy voucher'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.only(top: 8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    final method = _methodsData[_paymentMethod]!;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thanh toán',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _selectPaymentMethod,
            child: Row(
              children: [
                Icon(
                  method['icon'] as IconData,
                  color: method['color'] as Color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  method['label'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(CartProvider cart) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _summaryRow(
            'Tiền hàng',
            MoneyUtils.formatVnd(currencyFormat, cart.subtotal),
          ),
          _summaryRow(
            'Phí vận chuyển',
            MoneyUtils.formatVnd(currencyFormat, cart.deliveryFee),
          ),
          if (cart.discount > 0)
            _summaryRow(
              'Giảm giá',
              '- ${MoneyUtils.formatVnd(currencyFormat, cart.discount)}',
              color: Colors.red,
            ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thanh toán',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                MoneyUtils.formatVnd(currencyFormat, cart.total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(CartProvider cart, AddressProvider addr) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tổng cộng',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    MoneyUtils.formatVnd(currencyFormat, cart.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              height: 50,
              width: 140,
              child: FilledButton(
                onPressed: () => _handlePlaceOrder(cart, addr),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Đặt hàng',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVoucherPicker(CartProvider cart) async {
    final selectedVoucher = await Navigator.push<VoucherModel>(
      context,
      MaterialPageRoute(builder: (_) => const VoucherScreen(isPicker: true)),
    );

    if (selectedVoucher != null) {
      if (cart.subtotal < selectedVoucher.minOrderAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Chưa đủ đơn hàng tối thiểu ${MoneyUtils.formatVnd(currencyFormat, selectedVoucher.minOrderAmount)}',
            ),
          ),
        );
        return;
      }
      cart.setVoucher(selectedVoucher);
    }
  }

  void _selectPaymentMethod() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentMethodScreen(currentMethod: _paymentMethod),
      ),
    );
    if (result != null) setState(() => _paymentMethod = result);
  }

  void _handlePlaceOrder(
    CartProvider cart,
    AddressProvider addrProvider,
  ) async {
    final addr = addrProvider.selectedAddress;
    if (addr == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn địa chỉ!')));
      return;
    }

    final method = _methodsData[_paymentMethod]!;
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MockPaymentScreen(
          methodName: method['label'] as String,
          color: method['color'] as Color,
          icon: method['icon'] as IconData,
        ),
      ),
    );

    if (success == true) {
      // ── Notification ─────────────────────────────
      // Thông báo sẽ thêm sau khi có orderId (ở _showSuccess)

      setState(() => _isProcessing = true);
      try {
        final orderId = await cart.placeOrder(
          address: addr.detail,
          phone: addr.phoneNumber,
          paymentMethod: _paymentMethod,
        );
        if (mounted) {
          setState(() => _isProcessing = false);
          // Thêm thông báo đặt hàng thành công
          Provider.of<NotificationProvider>(
            context,
            listen: false,
          ).addNotification(
            title: '📦 Đặt hàng thành công!',
            body: 'Đơn hàng của bạn đã được tiếp nhận và đang chờ xác nhận.',
            type: NotifType.order,
            orderId: orderId,
          );
          _showSuccess(orderId);
        }
      } catch (e) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccess(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
            SizedBox(height: 16),
            Text(
              'Đặt hàng thành công!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            SizedBox(height: 8),
            Text(
              'Đơn hàng đã được lưu vào hệ thống.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text('VỀ TRANG CHỦ'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(orderId: orderId),
                      ),
                    );
                  },
                  child: const Text('XEM ĐƠN HÀNG'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: List.generate(
        30,
        (i) => Expanded(
          child: Container(
            height: 1.5,
            color: i % 2 == 0 ? Colors.blue : Colors.red,
            margin: const EdgeInsets.symmetric(horizontal: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
