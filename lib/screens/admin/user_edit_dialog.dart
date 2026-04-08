import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';

class UserEditDialog extends StatefulWidget {
  final UserModel? user;
  final Function(UserModel) onSave;

  const UserEditDialog({
    super.key,
    required this.user,
    required this.onSave,
  });

  @override
  State<UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<UserEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late String _selectedRole;
  bool _isDisabled = false;
  bool _isSaving = false;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _nameController = TextEditingController(text: widget.user!.name);
      _emailController = TextEditingController(text: widget.user!.email);
      _phoneController = TextEditingController(text: widget.user!.phone);
      _addressController = TextEditingController(text: widget.user!.address);
      _selectedRole = widget.user!.role;
      _isDisabled = widget.user!.isDisabled;
    } else {
      _nameController = TextEditingController();
      _emailController = TextEditingController();
      _phoneController = TextEditingController();
      _addressController = TextEditingController();
      _selectedRole = 'user';
      _isDisabled = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Create updated user model with new values
      final updatedUser = (widget.user ?? UserModel(
        userId: '',
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        role: _selectedRole,
        isDisabled: _isDisabled,
        createdAt: DateTime.now(),
      )).copyWith(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        role: _selectedRole,
        isDisabled: _isDisabled,
      );

      // Call onSave FIRST for optimistic update
      if (mounted) {
        widget.onSave(updatedUser);
      }

      // Then persist to Firestore
      if (widget.user != null) {
        await _userService.updateUser(widget.user!.userId, {
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'role': _selectedRole,
          'isDisabled': _isDisabled,
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lưu thành công'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user == null ? 'Thêm tài khoản' : 'Chỉnh sửa tài khoản'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên',
                hintText: 'Nhập tên',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Nhập email',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Điện thoại',
                hintText: 'Nhập số điện thoại',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ',
                hintText: 'Nhập địa chỉ',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'Vai trò'),
              items: const [
                DropdownMenuItem(value: 'user', child: Text('Khách hàng')),
                DropdownMenuItem(value: 'seller', child: Text('Bán hàng')),
                DropdownMenuItem(value: 'admin', child: Text('Quản trị')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedRole = value);
              },
            ),
            const SizedBox(height: 12),
            if (widget.user != null)
              CheckboxListTile(
                title: const Text('Vô hiệu hóa tài khoản'),
                value: _isDisabled,
                onChanged: (value) {
                  setState(() => _isDisabled = value ?? false);
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}
