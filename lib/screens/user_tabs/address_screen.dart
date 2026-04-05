import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/address_provider.dart';
import '../../models/address_model.dart';

class AddressScreen extends StatelessWidget {
  final bool isPicker; // Cờ kiểm tra xem là đang "Chọn" hay đang "Quản lý"
  const AddressScreen({super.key, this.isPicker = false});

  @override
  Widget build(BuildContext context) {
    final addressProvider = Provider.of<AddressProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Địa chỉ giao hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
            onPressed: () => _showAddressDialog(context, null),
          ),
        ],
      ),
      body: addressProvider.addresses.isEmpty
          ? _emptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: addressProvider.addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final addr = addressProvider.addresses[i];
                final isSelected = addressProvider.selectedAddress?.id == addr.id;

                return Dismissible(
                  key: Key(addr.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) => _showDeleteConfirm(context, addr, addressProvider),
                  background: Container(
                    padding: const EdgeInsets.only(right: 20),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.delete_sweep_outlined, color: Colors.white, size: 28),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor, width: isSelected ? 1.5 : 1),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          onTap: () {
                            addressProvider.selectAddress(addr);
                            if (isPicker && Navigator.canPop(context)) Navigator.pop(context);
                          },
                          leading: Radio<String>(
                            value: addr.id,
                            groupValue: addressProvider.selectedAddress?.id,
                            activeColor: AppTheme.primaryColor,
                            onChanged: (_) {
                              addressProvider.selectAddress(addr);
                              if (isPicker && Navigator.canPop(context)) Navigator.pop(context);
                            },
                          ),
                          title: Row(
                            children: [
                              Text(addr.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              if (addr.isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                  child: const Text('Mặc định', style: TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('${addr.receiverName} | ${addr.phoneNumber}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(addr.detail, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_note_rounded, color: AppTheme.textSecondary),
                            onPressed: () => _showAddressDialog(context, addr),
                          ),
                        ),
                        const Divider(height: 1, indent: 60, color: AppTheme.dividerColor),
                        // ── Bottom action for Set Default ──────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!addr.isDefault)
                                TextButton.icon(
                                  onPressed: () => addressProvider.updateAddress(
                                    AddressModel(
                                      id: addr.id, label: addr.label, receiverName: addr.receiverName,
                                      phoneNumber: addr.phoneNumber, detail: addr.detail, isDefault: true
                                    )),
                                  icon: const Icon(Icons.check_circle_outline, size: 16, color: AppTheme.textSecondary),
                                  label: const Text('Thiết lập mặc định', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                )
                              else
                                const Text('Địa chỉ đang là mặc định', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<bool?> _showDeleteConfirm(BuildContext context, AddressModel addr, AddressProvider provider) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn xóa địa chỉ "${addr.label}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy', style: TextStyle(color: AppTheme.textSecondary))),
          FilledButton(
            onPressed: () {
              provider.deleteAddress(addr.id);
              Navigator.pop(context, true);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xóa ngay'),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined, size: 80, color: AppTheme.textSecondary.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text('Bạn chưa lưu địa chỉ nào', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  void _showAddressDialog(BuildContext context, AddressModel? address) {
    final labelCtrl = TextEditingController(text: address?.label);
    final nameCtrl = TextEditingController(text: address?.receiverName);
    final phoneCtrl = TextEditingController(text: address?.phoneNumber);
    final detailCtrl = TextEditingController(text: address?.detail);
    bool isDefault = address?.isDefault ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text(address == null ? 'Thêm địa chỉ mới' : 'Cập nhật địa chỉ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên người nhận', prefixIcon: Icon(Icons.person_outline))),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Số điện thoại', prefixIcon: Icon(Icons.phone_outlined))),
              const SizedBox(height: 12),
              TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Tên gợi nhớ (VD: Nhà riêng, Công ty)', prefixIcon: Icon(Icons.label_outline))),
              const SizedBox(height: 12),
              TextField(controller: detailCtrl, decoration: const InputDecoration(labelText: 'Địa chỉ cụ thể', prefixIcon: Icon(Icons.location_on_outlined))),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Đặt làm địa chỉ mặc định', style: TextStyle(fontSize: 14)),
                value: isDefault, activeColor: AppTheme.primaryColor,
                onChanged: (val) => setDialogState(() => isDefault = val),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: FilledButton(
                  onPressed: () {
                    if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty || detailCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đủ thông tin!')));
                      return;
                    }
                    final provider = Provider.of<AddressProvider>(context, listen: false);
                    if (address == null) {
                      provider.addAddress(labelCtrl.text, nameCtrl.text, phoneCtrl.text, detailCtrl.text, isDefault);
                    } else {
                      provider.updateAddress(AddressModel(
                        id: address.id, label: labelCtrl.text, receiverName: nameCtrl.text,
                        phoneNumber: phoneCtrl.text, detail: detailCtrl.text, isDefault: isDefault,
                      ));
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Lưu thông tin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
