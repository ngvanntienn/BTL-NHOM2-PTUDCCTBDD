import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class MockPaymentScreen extends StatelessWidget {
  final String methodName;
  final Color color;
  final IconData icon;

  const MockPaymentScreen({
    super.key,
    required this.methodName,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // If banking, show Info screen
    final isBanking = methodName.contains('Chuyển khoản');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(methodName),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (isBanking) _buildBankingInfo(context) else _buildCodInfo(context),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 56,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hoàn tất đặt hàng', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy bỏ', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankingInfo(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.account_balance_outlined, size: 60, color: Colors.blue),
        const SizedBox(height: 20),
        const Text(
          'Thông tin chuyển khoản',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Vui lòng chuyển tiền theo thông tin bên dưới để hoàn tất đơn hàng',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 24),
        _infoItem('Ngân hàng', 'MB BANK (Quân Đội)'),
        _infoItem('Số tài khoản', '1234 5678 9999', isCopy: true),
        _infoItem('Chủ tài khoản', 'NGUYEN VAN A'),
        _infoItem('Nội dung CK', 'BTL FOOD APP 123', isCopy: true),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 12),
              Expanded(child: Text('Đơn hàng sẽ được xác nhận sau khi nhận được thanh toán.', style: TextStyle(fontSize: 12, color: Colors.blue))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCodInfo(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.wallet_rounded, size: 60, color: Colors.green),
        const SizedBox(height: 24),
        const Text('Thanh toán tiền mặt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          'Bạn sẽ thanh toán bằng tiền mặt cho Shipper khi nhận được hàng.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _infoItem(String label, String value, {bool isCopy = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.dividerColor))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          Row(
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              if (isCopy) ...[
                const SizedBox(width: 8),
                const Icon(Icons.copy_rounded, size: 16, color: Colors.blue),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
