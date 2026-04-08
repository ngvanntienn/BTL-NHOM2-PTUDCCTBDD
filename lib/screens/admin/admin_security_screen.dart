import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../home/admin_home.dart';
import '../login_screen.dart';

class AdminSecurityScreen extends StatefulWidget {
  const AdminSecurityScreen({super.key});

  @override
  State<AdminSecurityScreen> createState() => _AdminSecurityScreenState();
}

class _AdminSecurityScreenState extends State<AdminSecurityScreen> {
  static const String _defaultPin = '123456';
  static const String _pin = String.fromEnvironment(
    'ADMIN_SECURITY_PIN',
    defaultValue: _defaultPin,
  );

  final TextEditingController _pinController = TextEditingController();
  bool _checking = false;
  bool _obscure = true;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_checking) {
      return;
    }

    final String input = _pinController.text.trim();
    if (input.isEmpty) {
      _show('Vui lòng nhập mã bảo mật.', isError: true);
      return;
    }

    setState(() => _checking = true);
    try {
      if (input != _pin) {
        _show('Sai mã bảo mật.', isError: true);
        return;
      }

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => const AdminHomeScreen()),
      );
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _show(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : AppTheme.accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Xác thực bảo mật quản trị'),
        actions: <Widget>[
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Nhập mã bảo mật để vào màn quản trị',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pinController,
                    obscureText: _obscure,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _verify(),
                    decoration: InputDecoration(
                      labelText: 'Mã bảo mật',
                      prefixIcon: const Icon(Icons.security),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _checking ? null : _verify,
                      child: _checking
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Xác nhận'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
