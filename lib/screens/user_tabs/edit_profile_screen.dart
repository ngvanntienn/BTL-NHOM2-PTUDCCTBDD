import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _oldPwCtrl   = TextEditingController();
  final _newPwCtrl   = TextEditingController();
  final _confirmPwCtrl = TextEditingController();

  bool _loading = false;
  bool _showPwSection = false;
  bool _showOldPw = false;
  bool _showNewPw = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text    = widget.userData['name']    ?? '';
    _phoneCtrl.text   = widget.userData['phone']   ?? '';
    _addressCtrl.text = widget.userData['address'] ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _addressCtrl.dispose();
    _oldPwCtrl.dispose(); _newPwCtrl.dispose(); _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Tên không được để trống!', isError: true); return;
    }
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name':    _nameCtrl.text.trim(),
        'phone':   _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
      });
      _snack('Cập nhật thông tin thành công!');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('Lỗi: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPwCtrl.text != _confirmPwCtrl.text) {
      _snack('Mật khẩu xác nhận không khớp!', isError: true); return;
    }
    if (_newPwCtrl.text.length < 6) {
      _snack('Mật khẩu mới phải ít nhất 6 ký tự!', isError: true); return;
    }
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      // Re-authenticate
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: _oldPwCtrl.text);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPwCtrl.text);
      _snack('Đổi mật khẩu thành công!');
      _oldPwCtrl.clear(); _newPwCtrl.clear(); _confirmPwCtrl.clear();
      setState(() => _showPwSection = false);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _snack('Mật khẩu cũ không đúng!', isError: true);
      } else {
        _snack('Lỗi: ${e.message}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : AppTheme.accentColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Chỉnh sửa thông tin'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _saveProfile,
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                : const Text('Lưu', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    backgroundImage: (widget.userData['avatar'] != null &&
                            (widget.userData['avatar'] as String).isNotEmpty)
                        ? NetworkImage(widget.userData['avatar'] as String)
                        : null,
                    child: (widget.userData['avatar'] == null ||
                            (widget.userData['avatar'] as String).isEmpty)
                        ? Text(
                            (_nameCtrl.text.isNotEmpty ? _nameCtrl.text[0] : '?').toUpperCase(),
                            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 32, height: 32,
                      decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('Chạm để thay đổi ảnh đại diện',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),

            // Basic Info Card
            _card(
              children: [
                const _SectionLabel('THÔNG TIN CÁ NHÂN'),
                const SizedBox(height: 12),
                _field(_nameCtrl,    'Họ và tên',       Icons.person_outline),
                const SizedBox(height: 12),
                _field(_phoneCtrl,   'Số điện thoại',   Icons.phone_outlined, type: TextInputType.phone),
                const SizedBox(height: 12),
                _field(_addressCtrl, 'Địa chỉ',         Icons.location_on_outlined),
                const SizedBox(height: 8),
                // Email (read-only)
                TextFormField(
                  initialValue: widget.userData['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '',
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Email (không thể thay đổi)',
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Change Password Card
            _card(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionLabel('ĐỔI MẬT KHẨU'),
                    TextButton(
                      onPressed: () => setState(() => _showPwSection = !_showPwSection),
                      child: Text(_showPwSection ? 'Ẩn' : 'Thay đổi',
                          style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                if (_showPwSection) ...[
                  const SizedBox(height: 12),
                  _pwField(_oldPwCtrl, 'Mật khẩu hiện tại', _showOldPw, () => setState(() => _showOldPw = !_showOldPw)),
                  const SizedBox(height: 12),
                  _pwField(_newPwCtrl, 'Mật khẩu mới', _showNewPw, () => setState(() => _showNewPw = !_showNewPw)),
                  const SizedBox(height: 12),
                  _pwField(_confirmPwCtrl, 'Xác nhận mật khẩu mới', false, null),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _changePassword,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Xác nhận đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.dividerColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
        filled: true, fillColor: Colors.white,
      ),
    );
  }

  Widget _pwField(TextEditingController ctrl, String label, bool visible, VoidCallback? toggle) {
    return TextField(
      controller: ctrl,
      obscureText: !visible,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: toggle != null ? IconButton(
          icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: toggle,
        ) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.dividerColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
        filled: true, fillColor: Colors.white,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1, color: AppTheme.textSecondary));
}
