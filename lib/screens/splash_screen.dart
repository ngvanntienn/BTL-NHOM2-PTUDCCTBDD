import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_routes.dart';
import '../theme/app_theme.dart';
import 'home/seller_home.dart';
import 'home/user_home.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) {
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _go(const LoginScreen());
      return;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(<String, dynamic>{
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
        _go(const UserHomeScreen());
        return;
      }

      final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
      final String role = (data['role'] ?? 'user').toString();

      if (role == 'admin') {
        if (!mounted) {
          return;
        }
        Navigator.pushReplacementNamed(context, AppRoutes.adminHome);
      } else if (role == 'seller') {
        _go(const SellerHomeScreen());
      } else {
        _go(const UserHomeScreen());
      }
    } catch (_) {
      await FirebaseAuth.instance.signOut();
      _go(const LoginScreen());
    }
  }

  void _go(Widget page) {
    if (!mounted) {
      return;
    }
    Navigator.pushReplacement(
      context,
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, Animation<double> a, __, Widget child) {
          return FadeTransition(opacity: a, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(
                    Icons.fastfood_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'FoodExpress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 52),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    color: Colors.white.withOpacity(0.8),
                    strokeWidth: 2.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
