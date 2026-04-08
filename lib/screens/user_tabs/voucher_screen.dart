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
        title: const Text('Ví & Khuyến mãi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryColor),
            tooltip: 'Nhập mã',
            onPressed: () => _showEnterCodeDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vouchers')
            .doc(uid)
            .collection('items')
            .orderBy('expiresAt', descending: false)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 72,
                    color: AppTheme.textSecondary.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có voucher nào',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nhập mã khuyến mãi hoặc nhận voucher\ntừ các chương trình để sử dụng!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => _showEnterCodeDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Nhập mã giảm giá',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _voucherCard(context, docs[i]),
          );
        },
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

  Widget _voucherCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final code = data['code'] ?? 'CODE';
    final description = data['description'] ?? 'Khuyến mãi';
    final discountPercent = (data['discountPercent'] as num?)?.toInt() ?? 0;
    final minOrderAmount = (data['minOrderAmount'] as num?)?.toDouble() ?? 0;
    final expiry = (data['expiresAt'] as Timestamp?)?.toDate();
    final isExpired = expiry != null && expiry.isBefore(DateTime.now());
    final expiryStr = expiry != null
        ? 'HSD: ${expiry.day.toString().padLeft(2, '0')}/${expiry.month.toString().padLeft(2, '0')}/${expiry.year}'
        : '';

    return Opacity(
      opacity: isExpired ? 0.5 : 1,
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
              decoration: BoxDecoration(
                color: isExpired ? Colors.grey : AppTheme.primaryColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '-${discountPercent.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.local_offer_rounded,
                    color: Colors.white60,
                    size: 20,
                  ),
                  Icon(Icons.confirmation_num_outlined, color: Colors.white, size: 32),
                  SizedBox(height: 4),
                  Text('VOUCHER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                ],
              ),
            ),
            // Right part (Info)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 4,
                ),
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
                        Expanded(
                          child: Text(
                            description.isNotEmpty ? description : 'Khuyến mãi',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isExpired)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Hết hạn',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Text(
                            code,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Text(
                          expiryStr,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        Text('Mã: ${v.code}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                        if (isPicker)
                          const Text('Chọn ngay', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12))
                        else
                          const Text('Sắp hết hạn', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tối thiểu: ${minOrderAmount.toStringAsFixed(0)}đ',
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
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

  void _showEnterCodeDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Nhập mã khuyến mãi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'VD: FOOD50',
            prefixIcon: const Icon(
              Icons.local_offer_outlined,
              color: AppTheme.primaryColor,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Huỷ',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () async {
              final code = ctrl.text.trim().toUpperCase();
              if (code.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập mã voucher!'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
                return;
              }

              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) return;

              try {
                // Search voucher in main vouchers collection
                final voucherSnap = await FirebaseFirestore.instance
                    .collection('vouchers')
                    .where('code', isEqualTo: code)
                    .limit(1)
                    .get();

                if (voucherSnap.docs.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mã voucher không tồn tại!'),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  return;
                }

                final voucherDoc = voucherSnap.docs.first;
                final voucherData = voucherDoc.data();
                final isActive = voucherData['isActive'] ?? false;
                final expiryDate = (voucherData['expiryDate'] as Timestamp?)
                    ?.toDate();
                final isExpired =
                    expiryDate != null && expiryDate.isBefore(DateTime.now());
                final usageLimit = voucherData['usageLimit'] ?? 0;
                final currentUsage = voucherData['currentUsage'] ?? 0;
                final exceedsUsage = currentUsage >= usageLimit;

                if (!isActive) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Voucher này đã bị vô hiệu hóa!'),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  return;
                }

                if (isExpired) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Voucher này đã hết hạn!'),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  return;
                }

                if (exceedsUsage) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Voucher này đã được sử dụng hết lượt!'),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  return;
                }

                // Check if user already has this voucher
                final userVouchersSnap = await FirebaseFirestore.instance
                    .collection('vouchers')
                    .doc(uid)
                    .collection('items')
                    .where('code', isEqualTo: code)
                    .limit(1)
                    .get();

                if (userVouchersSnap.docs.isNotEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bạn đã có voucher này rồi!'),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  return;
                }

                // Add voucher to user's wallet
                await FirebaseFirestore.instance
                    .collection('vouchers')
                    .doc(uid)
                    .collection('items')
                    .add({
                      'code': voucherData['code'],
                      'description': voucherData['description'],
                      'discountPercent': voucherData['discountPercent'] ?? 0,
                      'minOrderAmount': voucherData['minOrderAmount'] ?? 0,
                      'expiresAt': voucherData['expiryDate'],
                      'isActive': voucherData['isActive'],
                      'savedAt': FieldValue.serverTimestamp(),
                      'createdBy': voucherData['createdBy'],
                    });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Đã thêm voucher thành công! 🎉'),
                      backgroundColor: AppTheme.accentColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: $e'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Áp dụng',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
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
