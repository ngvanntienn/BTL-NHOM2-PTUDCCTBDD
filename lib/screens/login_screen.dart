import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../app_routes.dart';
import '../services/firestore_schema.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';
import 'seller/seller_interview_game_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Vui long nhap day du thong tin.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final UserCredential cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final DocumentSnapshot<Map<String, dynamic>> userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(cred.user!.uid)
              .get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set(<String, dynamic>{
              'userId': cred.user!.uid,
              'name': cred.user!.displayName ?? 'Người dùng',
              'email': cred.user!.email ?? email,
              'role': 'user',
              'phone': '',
              'address': '',
              'createdAt': FieldValue.serverTimestamp(),
              'avatar': cred.user!.photoURL ?? '',
              'isDisabled': false,
            });

        if (mounted) {
          _showSnackBar('Đã đồng bộ tài khoản Firebase vào hệ thống.');
        }
        await _navigateByRole('user');
        return;
      }

      final bool isDisabled = (userDoc.data()?['isDisabled'] as bool?) ?? false;
      if (isDisabled) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          _showSnackBar('Tài khoản đã bị khóa.', isError: true);
        }
        return;
      }

      final String role = (userDoc.data()?['role'] ?? 'user').toString();
      if (mounted) {
        await _navigateByRole(role);
      }
    } on FirebaseAuthException {
      if (mounted) {
        _showSnackBar('Sai email hoặc mật khẩu.', isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Đăng nhập thất bại: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      UserCredential userCred;
      if (kIsWeb) {
        final GoogleAuthProvider provider = GoogleAuthProvider()
          ..setCustomParameters(<String, String>{'prompt': 'select_account'});
        userCred = await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          return;
        }

        final GoogleSignInAuthentication auth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        );
        userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final User? user = userCred.user;
      if (user == null) {
        throw Exception('Không lấy được thông tin tài khoản Google.');
      }

      final DocumentReference<Map<String, dynamic>> docRef = FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid);
      final DocumentSnapshot<Map<String, dynamic>> docSnap = await docRef.get();

      if (!docSnap.exists) {
        await docRef.set(<String, dynamic>{
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
        await _navigateByRole('user');
      } else {
        final bool isDisabled =
            (docSnap.data()?['isDisabled'] as bool?) ?? false;
        if (isDisabled) {
          if (!kIsWeb) {
            await GoogleSignIn().signOut();
          }
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            _showSnackBar('Tài khoản đã bị khóa.', isError: true);
          }
          return;
        }

        final String role = (docSnap.data()?['role'] ?? 'user').toString();
        await _navigateByRole(role);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Đăng nhập Google thất bại: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Future<bool> _hasPassedSellerInterview(String sellerId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection(FirestoreCollections.sellerInterviewAttempts)
        .where('sellerId', isEqualTo: sellerId)
        .where('passed', isEqualTo: true)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<void> _navigateByRole(String role) async {
    if (!mounted) {
      return;
    }

    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, AppRoutes.adminHome);
      return;
    }

    if (role == 'seller') {
      final String sellerId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (sellerId.isEmpty) {
        _showSnackBar('Không tìm thấy tài khoản seller.', isError: true);
        return;
      }

      final bool hasPassed = await _hasPassedSellerInterview(sellerId);
      if (!mounted) {
        return;
      }

      if (hasPassed) {
        Navigator.pushReplacementNamed(context, AppRoutes.sellerHome);
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const SellerInterviewGameScreen(
            requireCompletionBeforeContinue: true,
          ),
        ),
      );
      return;
    }

    Navigator.pushReplacementNamed(context, AppRoutes.userHome);
  }

  void _showSnackBar(String message, {bool isError = false}) {
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 56),
              Row(
                children: <Widget>[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.fastfood_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
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
              const SizedBox(height: 32),
              const Text(
                'Đăng nhập',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tiep tuc hanh trinh an ngon cung ban',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
                    },
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Đăng nhập'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                  icon: const Icon(Icons.g_mobiledata, size: 26),
                  label: _isGoogleLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Đăng nhập bằng Google'),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text('Chưa có tài khoản?'),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text('Đăng ký ngay'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.adminHome);
                },
                child: const Text('Dev shortcut: vao Admin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
