import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';
import '../seller/seller_panel.dart';
import 'address_screen.dart';
import 'edit_profile_screen.dart';
import 'payment_method_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) {
      return;
    }

    final DocumentSnapshot<Map<String, dynamic>> doc = await _db
        .collection('users')
        .doc(uid)
        .get();

    if (!mounted) {
      return;
    }

    setState(() {
      _userData = doc.data();
      _loading = false;
    });
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _openEditProfile() async {
    try {
      final bool? updated = await Navigator.push<bool>(
        context,
        MaterialPageRoute<bool>(
          builder: (_) =>
              EditProfileScreen(userData: _userData ?? <String, dynamic>{}),
        ),
      );
      if (updated == true) {
        await _loadUser();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể mở màn chỉnh sửa: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final String name = (_userData?['name'] ?? 'Người dùng').toString();
    final String email = (_userData?['email'] ?? _auth.currentUser?.email ?? '')
        .toString();
    final String role = (_userData?['role'] ?? 'user').toString();
    final String avatar = (_userData?['avatar'] ?? '').toString();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadUser,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                    backgroundImage: avatar.isNotEmpty
                        ? NetworkImage(avatar)
                        : null,
                    child: avatar.isEmpty
                        ? Text(
                            name.isEmpty ? 'U' : name[0].toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                              fontSize: 22,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Role: $role',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _tile(
              icon: Icons.person_outline,
              title: 'Chỉnh sửa thông tin',
              subtitle: 'Cập nhật họ tên, email, mật khẩu',
              onTap: _openEditProfile,
            ),
            _tile(
              icon: Icons.receipt_long_outlined,
              title: 'Lịch sử đơn hàng',
              subtitle: 'Theo dõi trạng thái đơn hàng',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.orderHistory,
                  arguments: const OrderHistoryRouteArgs(initialFilter: 'all'),
                );
              },
            ),
            _tile(
              icon: Icons.favorite_border,
              title: 'Món yêu thích',
              subtitle: 'Xem danh sách đã lưu',
              onTap: () => Navigator.pushNamed(context, AppRoutes.favorites),
            ),
            _tile(
              icon: Icons.local_offer_outlined,
              title: 'Ví voucher',
              subtitle: 'Xem và chọn mã giảm giá',
              onTap: () => Navigator.pushNamed(context, AppRoutes.voucher),
            ),
            _tile(
              icon: Icons.location_on_outlined,
              title: 'Địa chỉ giao hàng',
              subtitle: 'Thêm/sửa/xóa địa chỉ',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const AddressScreen(),
                  ),
                );
              },
            ),
            _tile(
              icon: Icons.payment_outlined,
              title: 'Phương thức thanh toán',
              subtitle: 'Quản lý phương thức thanh toán',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const PaymentMethodScreen(),
                  ),
                );
              },
            ),
            if (role == 'seller')
              _tile(
                icon: Icons.storefront_outlined,
                title: 'Seller Panel',
                subtitle: 'Quản lý cửa hàng và đơn hàng',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const SellerPanel(),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text(
                  'Đăng xuất',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
