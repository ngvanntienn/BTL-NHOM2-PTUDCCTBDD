import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _role = 'user';

  Future<void> _registerUser() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _addressController.text.isEmpty) {
      _showSnackBar('Vui lòng nhập đầy đủ thông tin!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text);

      String uid = userCredential.user!.uid;

      UserModel newUser = UserModel(
        userId: uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: _role,
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        createdAt: DateTime.now(),
        isDisabled: false,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(newUser.toMap());

      if (mounted) {
        _showSnackBar('Đăng ký thành công! Hãy đăng nhập ngay.');
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Đăng ký thất bại!';
      if (e.code == 'weak-password') {
        msg = 'Mật khẩu quá yếu (tối thiểu 6 ký tự).';
      } else if (e.code == 'email-already-in-use') {
        msg = 'Email này đã được sử dụng.';
      }
      if (mounted) _showSnackBar(msg, isError: true);
    } catch (e) {
      if (mounted) _showSnackBar('Lỗi: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.fastfood_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'FoodExpress',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              Text('Tạo tài khoản mới',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      )),
              const SizedBox(height: 6),
              Text('Điền thông tin bên dưới để bắt đầu.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
              const SizedBox(height: 32),

              // ── Fields ──────────────────────────────────────────────
              _buildField(_nameController, 'Họ và tên', Icons.person_outline),
              const SizedBox(height: 14),
              _buildField(_emailController, 'Email', Icons.email_outlined, keyboard: TextInputType.emailAddress),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _buildField(_phoneController, 'Số điện thoại', Icons.phone_outlined, keyboard: TextInputType.phone),
              const SizedBox(height: 14),
              _buildField(_addressController, 'Địa chỉ', Icons.location_on_outlined),
              const SizedBox(height: 14),

              // ── Role Selector ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.dividerColor, width: 1.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _role,
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryColor),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('Người dùng (User)')),
                      DropdownMenuItem(value: 'seller', child: Text('Người bán (Seller)')),
                    ],
                    onChanged: (val) => setState(() => _role = val ?? 'user'),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Submit ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _registerUser,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Đăng ký', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Đã có tài khoản?', style: TextStyle(color: AppTheme.textSecondary)),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đăng nhập ngay',
                        style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }
}
