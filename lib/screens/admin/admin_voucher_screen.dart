import 'package:flutter/material.dart';
import '../../models/voucher_model.dart';
import '../../services/voucher_service.dart';
import '../../theme/app_theme.dart';

class AdminVoucherScreen extends StatefulWidget {
  const AdminVoucherScreen({Key? key}) : super(key: key);

  @override
  State<AdminVoucherScreen> createState() => _AdminVoucherScreenState();
}

class _AdminVoucherScreenState extends State<AdminVoucherScreen> {
  final _voucherService = VoucherService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Quản lý Voucher',
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
        stream: _voucherService.getAllVouchersForAdmin(),
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
                    'Giảm giá:',
                    voucher.type == 'PERCENTAGE'
                        ? '${voucher.discountPercent}%'
                        : '${voucher.fixedDiscount}đ',
                  ),
                  _buildInfoRow(
                    'Đơn tối thiểu:',
                    '${voucher.minOrderAmount.toStringAsFixed(0)}đ',
                  ),
                  _buildInfoRow(
                    'Lượt sử dụng:',
                    '${voucher.currentUsage}/${voucher.usageLimit}',
                  ),
                  _buildInfoRow(
                    'Hết hạn:',
                    voucher.expiryDate.toString().split(' ')[0],
                  ),
                ],
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
    return Row(
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
    );
  }

  void _showVoucherDialog(BuildContext context, [VoucherModel? existing]) {
    showDialog(
      context: context,
      builder: (context) => _VoucherFormDialog(
        existing: existing,
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
  final Function(VoucherModel) onSubmit;

  const _VoucherFormDialog({this.existing, required this.onSubmit});

  @override
  State<_VoucherFormDialog> createState() => _VoucherFormDialogState();
}

class _VoucherFormDialogState extends State<_VoucherFormDialog> {
  late final TextEditingController _codeController;
  late final TextEditingController _descController;
  late final TextEditingController _discountController;
  late final TextEditingController _minOrderController;
  late final TextEditingController _usageLimitController;
  late final TextEditingController _maxDiscountController;

  late String _type;
  late DateTime _expiryDate;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _type = existing?.type ?? 'PERCENTAGE';
    _expiryDate =
        existing?.expiryDate ?? DateTime.now().add(const Duration(days: 30));

    _codeController = TextEditingController(text: existing?.code ?? '');
    _descController = TextEditingController(text: existing?.description ?? '');
    _discountController = TextEditingController(
      text: existing?.discountPercent.toString() ?? '',
    );
    _minOrderController = TextEditingController(
      text: existing?.minOrderAmount.toString() ?? '',
    );
    _usageLimitController = TextEditingController(
      text: existing?.usageLimit.toString() ?? '',
    );
    _maxDiscountController = TextEditingController(
      text: existing?.maxDiscountAmount?.toString() ?? '',
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
                'Tạo/Sửa Voucher',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildTextField('Mã voucher', _codeController),
              _buildTextField('Mô tả', _descController),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('Giảm giá (%)', _discountController),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      'Đơn tối thiểu',
                      _minOrderController,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Lượt sử dụng',
                      _usageLimitController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField('Max giảm', _maxDiscountController),
                  ),
                ],
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
                      'Lưu',
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

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
        ),
      ),
    );
  }

  void _submit() {
    final voucher = VoucherModel(
      id: widget.existing?.id ?? '',
      code: _codeController.text.toUpperCase(),
      description: _descController.text,
      discountPercent: double.tryParse(_discountController.text) ?? 0,
      maxDiscountAmount: double.tryParse(_maxDiscountController.text),
      minOrderAmount: double.tryParse(_minOrderController.text) ?? 0,
      usageLimit: int.tryParse(_usageLimitController.text) ?? 100,
      currentUsage: widget.existing?.currentUsage ?? 0,
      expiryDate: _expiryDate,
      isActive: true,
      createdBy: 'admin',
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      applicableCategories: const [],
      type: _type,
      fixedDiscount: null,
    );

    widget.onSubmit(voucher);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descController.dispose();
    _discountController.dispose();
    _minOrderController.dispose();
    _usageLimitController.dispose();
    _maxDiscountController.dispose();
    super.dispose();
  }
}
