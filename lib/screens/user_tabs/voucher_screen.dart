import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/voucher_provider.dart';
import '../../models/voucher_model.dart';

class VoucherScreen extends StatelessWidget {
  final bool isPicker; // Cờ nếu là từ checkout
  const VoucherScreen({super.key, this.isPicker = false});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VoucherProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isPicker ? 'Chọn Voucher' : 'Kho Voucher', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: provider.vouchers.isEmpty
          ? _emptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.vouchers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final v = provider.vouchers[i];
                return _buildVoucherCard(context, v, currencyFormat);
              },
            ),
    );
  }

  Widget _buildVoucherCard(BuildContext context, VoucherModel v, NumberFormat format) {
    return GestureDetector(
      onTap: () {
        if (isPicker) Navigator.pop(context, v);
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            // Left part (Icon/Label)
            Container(
              width: 90,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_num_outlined, color: Colors.white, size: 32),
                  SizedBox(height: 4),
                  Text('VOUCHER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                ],
              ),
            ),
            // Right part (Info)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(v.type == VoucherType.percentage ? 'Giảm ${v.value}%' : 'Giảm ${format.format(v.value * 1000)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Đơn tối thiểu ${format.format(v.minOrderAmount * 1000)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mã: ${v.code}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                        if (isPicker)
                          const Text('Chọn ngay', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12))
                        else
                          const Text('Sắp hết hạn', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 80, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text('Bạn không có voucher nào khả dụng'),
        ],
      ),
    );
  }
}
