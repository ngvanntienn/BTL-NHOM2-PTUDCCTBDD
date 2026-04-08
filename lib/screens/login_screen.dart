import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';
import 'home/user_home.dart';
import 'home/seller_home.dart';
import 'home/admin_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  // ─── Đăng nhập Email/Password ───────────────────────────────────────
  Future<void> _handleLogin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text;

    // Admin hardcoded
    if (email == 'admin@gmail.com' && password == 'admin123') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AdminHomeScreen()));
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Vui lòng nhập đầy đủ thông tin', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        if (mounted) _showSnackBar('Tài khoản không tồn tại trên hệ thống.', isError: true);
        return;
      }

      bool isDisabled = userDoc.get('isDisabled') ?? false;
      if (isDisabled) {
        await FirebaseAuth.instance.signOut();
        if (mounted) _showSnackBar('Tài khoản của bạn đã bị khóa. Liên hệ hỗ trợ để biết thêm chi tiết.', isError: true);
        return;
      }

      String role = userDoc.get('role') ?? 'user';
      if (mounted) _navigateByRole(role);
    } on FirebaseAuthException catch (e) {
      String msg = 'Đăng nhập thất bại!';
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        msg = 'Sai email hoặc mật khẩu.';
      }
      if (mounted) _showSnackBar(msg, isError: true);
    } catch (e) {
      if (mounted) _showSnackBar('Lỗi: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Đăng nhập Google ───────────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // Người dùng bấm huỷ
        setState(() => _isGoogleLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCred.user!;

      // Kiểm tra tài khoản đã tồn tại chưa, nếu chưa tạo mới trên Firestore
      final docRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        await docRef.set({
          'userId': user.uid,
          'name': user.displayName ?? 'Người dùng',
          'email': user.email ?? '',
          'role': 'user',
          'phone': '',
          'address': '',
          'createdAt': FieldValue.serverTimestamp(),
          'avatar': user.photoURL ?? '',
          'isDisabled': false,
        });
      } else {
        // Kiểm tra tài khoản có bị khóa không
        bool isDisabled = docSnap.get('isDisabled') ?? false;
        if (isDisabled) {
          await GoogleSignIn().signOut();
          await FirebaseAuth.instance.signOut();
          if (mounted) _showSnackBar('Tài khoản của bạn đã bị khóa. Liên hệ hỗ trợ để biết thêm chi tiết.', isError: true);
          if (mounted) setState(() => _isGoogleLoading = false);
          return;
        }
      }

      if (mounted) _navigateByRole('user'); // Google login → luôn vào User Home
    } catch (e) {
      if (mounted) _showSnackBar('Lỗi đăng nhập Google: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _navigateByRole(String role) {
    if (role == 'admin') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AdminHomeScreen()));
    } else if (role == 'seller') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const SellerHomeScreen()));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const UserHomeScreen()));
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : AppTheme.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // Logo + App name
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.fastfood, color: Colors.white, size: 32),
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
              const SizedBox(height: 36),

              Text('Chào mừng trở lại! 👋',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1C1C1E),
                      )),
              const SizedBox(height: 8),
              Text('Đăng nhập để tiếp tục đặt món yêu thích.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF8E8E93),
                      )),
              const SizedBox(height: 40),

              // Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: 'example@email.com',
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Quên mật khẩu?',
                      style: TextStyle(color: AppTheme.primaryColor)),
                ),
              ),
              const SizedBox(height: 24),

              // Sign In Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Đăng nhập',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),

              // Divider
              Row(
                children: const [
                  Expanded(child: Divider(color: Color(0xFFEEEEEE))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('hoặc', style: TextStyle(color: Color(0xFF8E8E93))),
                  ),
                  Expanded(child: Divider(color: Color(0xFFEEEEEE))),
                ],
              ),
              const SizedBox(height: 24),

              // Google Sign In Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEEEEEE), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isGoogleLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: AppTheme.primaryColor, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google G icon (tự vẽ bằng text vì không có asset)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFDB4437),
                              ),
                              child: const Center(
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Tiếp tục với Google',
                              style: TextStyle(
                                color: Color(0xFF1C1C1E),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có tài khoản?',
                      style: TextStyle(color: Color(0xFF8E8E93))),
                  TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen())),
                    child: const Text('Tạo tài khoản mới',
                        style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
