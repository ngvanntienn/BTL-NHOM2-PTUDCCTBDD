import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/voucher_model.dart';
import '../../providers/voucher_provider.dart';
import '../../theme/app_theme.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key, this.isPicker = false});

  final bool isPicker;

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'd',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VoucherProvider>(context, listen: false).fetchVouchers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.isPicker ? 'Chọn voucher' : 'Ví voucher'),
      ),
      body: Consumer<VoucherProvider>(
        builder: (_, VoucherProvider provider, __) {
          final List<VoucherModel> vouchers = provider.vouchers;

          if (vouchers.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có voucher khả dụng.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: vouchers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, int i) => _card(vouchers[i]),
          );
        },
      ),
    );
  }

  Widget _card(VoucherModel v) {
    final bool disabled = !v.canUse;
    final double percent = v.discountPercent > 0
        ? v.discountPercent
        : (v.voucherType == VoucherType.percentage ? (v.value ?? 0) : 0);

    final String discountLabel = v.voucherType == VoucherType.fixed
        ? _currency.format(v.fixedDiscount ?? v.value ?? 0)
        : '${percent.toStringAsFixed(0)}%';

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: GestureDetector(
        onTap: disabled
            ? null
            : () {
                if (widget.isPicker) {
                  Navigator.pop(context, v);
                }
              },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 96,
                height: 112,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(14),
                  ),
                ),
                child: Center(
                  child: Text(
                    '-$discountLabel',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        v.code,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        v.description.isEmpty
                            ? 'Voucher khuyến mãi'
                            : v.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Đơn tối thiểu: ${_currency.format(v.minOrderAmount)}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'HSD: ${v.expiryDate.day.toString().padLeft(2, '0')}/${v.expiryDate.month.toString().padLeft(2, '0')}/${v.expiryDate.year}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.isPicker && !disabled)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.check_circle_outline, color: Colors.green),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

