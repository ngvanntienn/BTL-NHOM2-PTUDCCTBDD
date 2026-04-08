import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/voucher_model.dart';
import '../../services/voucher_service.dart';
import '../../theme/app_theme.dart';

class SellerVoucherScreen extends StatefulWidget {
  const SellerVoucherScreen({Key? key}) : super(key: key);

  @override
  State<SellerVoucherScreen> createState() => _SellerVoucherScreenState();
}

class _SellerVoucherScreenState extends State<SellerVoucherScreen> {
  final _voucherService = VoucherService();
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final sellerId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Quản lý Voucher Cửa hàng',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        onPressed: () => _showVoucherDialog(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<VoucherModel>>(
        stream: _voucherService.getSellerVouchers(sellerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          final vouchers = snapshot.data ?? [];

          if (vouchers.isEmpty) {
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
                    'Chưa có voucher nào',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tạo voucher để khuyến khích khách hàng',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vouchers.length,
            itemBuilder: (context, index) =>
                _buildVoucherCard(context, vouchers[index]),
          );
        },
      ),
    );
  }

  Widget _buildVoucherCard(BuildContext context, VoucherModel voucher) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mã: ${voucher.code}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        voucher.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: voucher.isActive && !voucher.isExpired
                            ? Colors.green[50]
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        voucher.isActive && !voucher.isExpired
                            ? 'Hoạt động'
                            : 'Hết hạn',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: voucher.isActive && !voucher.isExpired
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${voucher.discountPercent}% OFF',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    'Đơn tối thiểu:',
                    '${voucher.minOrderAmount.toStringAsFixed(0)}đ',
                  ),
                  _buildInfoRow(
                    'Lượt sử dụng:',
                    '${voucher.currentUsage}/${voucher.usageLimit}',
                  ),
                  _buildInfoRow(
                    'Tỉ lệ sử dụng:',
                    '${((voucher.currentUsage / voucher.usageLimit) * 100).toStringAsFixed(0)}%',
                  ),
                  _buildInfoRow(
                    'Hết hạn:',
                    voucher.expiryDate.toString().split(' ')[0],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Progress bar for usage
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: voucher.currentUsage / voucher.usageLimit,
                minHeight: 6,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  voucher.currentUsage / voucher.usageLimit > 0.8
                      ? Colors.orange
                      : AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showVoucherDialog(context, voucher),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Sửa'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteVoucher(voucher.id),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Xóa'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showVoucherDialog(BuildContext context, [VoucherModel? existing]) {
    showDialog(
      context: context,
      builder: (context) => _VoucherFormDialog(
        existing: existing,
        sellerId: _auth.currentUser?.uid ?? '',
        onSubmit: (voucher) =>
            _saveVoucher(voucher, isUpdate: existing != null),
      ),
    );
  }

  Future<void> _saveVoucher(
    VoucherModel voucher, {
    bool isUpdate = false,
  }) async {
    try {
      if (isUpdate) {
        await _voucherService.updateVoucher(voucher.id, voucher);
      } else {
        await _voucherService.createVoucher(voucher);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isUpdate ? 'Cập nhật thành công' : 'Tạo thành công'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _deleteVoucher(String voucherId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa voucher'),
        content: const Text('Bạn chắc chắn muốn xóa voucher này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _voucherService.deleteVoucher(voucherId);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Xóa thành công')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }
  }
}

class _VoucherFormDialog extends StatefulWidget {
  final VoucherModel? existing;
  final String sellerId;
  final Function(VoucherModel) onSubmit;

  const _VoucherFormDialog({
    this.existing,
    required this.sellerId,
    required this.onSubmit,
  });

  @override
  State<_VoucherFormDialog> createState() => _VoucherFormDialogState();
}

class _VoucherFormDialogState extends State<_VoucherFormDialog> {
  late final TextEditingController _codeController;
  late final TextEditingController _descController;
  late final TextEditingController _discountController;
  late final TextEditingController _minOrderController;
  late final TextEditingController _usageLimitController;

  late DateTime _expiryDate;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _expiryDate =
        existing?.expiryDate ?? DateTime.now().add(const Duration(days: 30));

    _codeController = TextEditingController(text: existing?.code ?? '');
    _descController = TextEditingController(text: existing?.description ?? '');
    _discountController = TextEditingController(
      text: existing != null && existing.discountPercent != 0
          ? existing.discountPercent.toStringAsFixed(0)
          : '',
    );
    _minOrderController = TextEditingController(
      text: existing != null && existing.minOrderAmount != 0
          ? existing.minOrderAmount.toStringAsFixed(0)
          : '',
    );
    _usageLimitController = TextEditingController(
      text: existing?.usageLimit.toString() ?? '100',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tạo Voucher Cửa hàng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildTextField('Mã voucher (VD: SUMMER40) *', _codeController),
              _buildTextField('Mô tả *', _descController, maxLines: 2),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Giảm giá (%) *',
                      _discountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      'Đơn tối thiểu (đ)',
                      _minOrderController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              _buildTextField(
                'Lượt sử dụng tối đa',
                _usageLimitController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              ListTile(
                title: const Text('Hết hạn', style: TextStyle(fontSize: 12)),
                subtitle: Text(_expiryDate.toString().split(' ')[0]),
                trailing: const Icon(Icons.calendar_today, size: 16),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _expiryDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _expiryDate = date);
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text(
                      'Tạo',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
        ),
      ),
    );
  }

  void _submit() {
    // Validation
    final code = _codeController.text.trim().toUpperCase();
    final description = _descController.text.trim();
    final discountText = _discountController.text
        .trim()
        .replaceAll('%', '')
        .trim();
    final minOrderText = _minOrderController.text.trim();

    if (code.isEmpty) {
      _showError('Vui lòng nhập mã voucher');
      return;
    }

    if (description.isEmpty) {
      _showError('Vui lòng nhập mô tả voucher');
      return;
    }

    if (discountText.isEmpty) {
      _showError('Vui lòng nhập phần trăm giảm giá');
      return;
    }

    final discountPercent = double.tryParse(discountText);
    if (discountPercent == null ||
        discountPercent <= 0 ||
        discountPercent > 100) {
      _showError('Giảm giá phải từ 1% đến 100%');
      return;
    }

    if (minOrderText.isNotEmpty) {
      final minOrder = double.tryParse(minOrderText);
      if (minOrder == null || minOrder < 0) {
        _showError('Đơn tối thiểu phải là số dương');
        return;
      }
    }

    final minOrder = minOrderText.isNotEmpty
        ? (double.tryParse(minOrderText) ?? 0.0)
        : 0.0;

    final voucher = VoucherModel(
      id: widget.existing?.id ?? '',
      code: code,
      description: description,
      discountPercent: discountPercent,
      maxDiscountAmount: null,
      minOrderAmount: minOrder,
      usageLimit: int.tryParse(_usageLimitController.text.trim()) ?? 100,
      currentUsage: widget.existing?.currentUsage ?? 0,
      expiryDate: _expiryDate,
      isActive: true,
      createdBy: widget.sellerId,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      applicableCategories: const [],
      type: 'PERCENTAGE',
      fixedDiscount: null,
    );

    widget.onSubmit(voucher);
    Navigator.pop(context);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descController.dispose();
    _discountController.dispose();
    _minOrderController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }
}
