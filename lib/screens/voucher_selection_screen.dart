import 'package:flutter/material.dart';
import '../models/voucher_model.dart';
import '../services/voucher_service.dart';
import '../theme/app_theme.dart';

class VoucherSelectionScreen extends StatefulWidget {
  final String? categoryFilter;
  final double totalAmount;

  const VoucherSelectionScreen({
    Key? key,
    this.categoryFilter,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<VoucherSelectionScreen> createState() => _VoucherSelectionScreenState();
}

class _VoucherSelectionScreenState extends State<VoucherSelectionScreen> {
  final _voucherService = VoucherService();
  String _searchQuery = '';
  VoucherModel? _selectedVoucher;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Chọn Voucher',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context, null),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Tìm mã voucher...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.dividerColor),
                ),
                isDense: true,
              ),
            ),
          ),

          // Vouchers List
          Expanded(
            child: FutureBuilder<List<VoucherModel>>(
              future: _getAvailableVouchers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  );
                }

                final vouchers = snapshot.data ?? [];

                // Filter by search query
                final filtered = vouchers
                    .where(
                      (v) => v.code.toUpperCase().contains(
                        _searchQuery.toUpperCase(),
                      ),
                    )
                    .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Không có voucher nào',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _buildVoucherOption(context, filtered[index]),
                );
              },
            ),
          ),

          // Apply Button
          if (_selectedVoucher != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _selectedVoucher),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Áp dụng Voucher',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVoucherOption(BuildContext context, VoucherModel voucher) {
    final isApplicable = widget.totalAmount >= voucher.minOrderAmount;
    final isSelected = _selectedVoucher?.id == voucher.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: isApplicable
            ? () => setState(() => _selectedVoucher = voucher)
            : null,
        enabled: isApplicable,
        selectedTileColor: AppTheme.primaryColor.withOpacity(0.1),
        selected: isSelected,
        title: Text(
          voucher.code,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isApplicable ? AppTheme.textPrimary : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              voucher.description,
              style: TextStyle(
                fontSize: 12,
                color: isApplicable ? AppTheme.textSecondary : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Giảm: ${voucher.discountPercent.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isApplicable ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Tối thiểu: ${voucher.minOrderAmount.toStringAsFixed(0)}đ',
                  style: TextStyle(
                    fontSize: 11,
                    color: isApplicable ? AppTheme.textSecondary : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
            : const Icon(
                Icons.radio_button_unchecked,
                color: AppTheme.dividerColor,
              ),
      ),
    );
  }

  Future<List<VoucherModel>> _getAvailableVouchers() async {
    try {
      if (widget.categoryFilter != null) {
        // Get vouchers for specific category
        final stream = _voucherService.getVouchersForCategory(
          widget.categoryFilter!,
        );
        return stream.first;
      } else {
        // Get all active vouchers
        final stream = _voucherService.getActiveVouchers();
        return stream.first;
      }
    } catch (e) {
      return [];
    }
  }
}
