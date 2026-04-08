import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PaymentMethodScreen extends StatefulWidget {
  final String currentMethod;
  const PaymentMethodScreen({super.key, this.currentMethod = 'cash'});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  late String _selectedMethod;

  final _methods = [
    {
      'id': 'banking', 
      'label': 'Chuyển khoản Ngân hàng', 
      'subtitle': 'Internet Banking hoặc App Ngân hàng', 
      'icon': Icons.account_balance_outlined, 
      'color': Colors.blue
    },
    {
      'id': 'cash', 
      'label': 'Thanh toán khi nhận hàng (COD)', 
      'subtitle': 'Thanh toán tiền mặt cho Shipper', 
      'icon': Icons.currency_exchange_rounded, 
      'color': Colors.green
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.currentMethod;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Phương thức thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          ..._methods.map((m) {
            final isSel = _selectedMethod == m['id'];
            return Column(
              children: [
                _buildMethodTile(m, isSel),
                const Divider(height: 1, indent: 64, color: AppTheme.dividerColor),
              ],
            );
          }).toList(),
          const Spacer(),
          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildMethodTile(Map<String, dynamic> m, bool isSel) {
    return InkWell(
      onTap: () => setState(() => _selectedMethod = m['id'] as String),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: (m['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(m['icon'] as IconData, color: m['color'] as Color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m['label'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(m['subtitle'] as String, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            if (isSel)
              const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 24)
            else
              const Icon(Icons.radio_button_off, size: 24, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: () => Navigator.pop(context, _selectedMethod),
          style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Đồng ý', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }
}
