import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_theme.dart';
import '../login_screen.dart';
import '../user_tabs/edit_profile_screen.dart';

class SellerSettingsScreen extends StatefulWidget {
  const SellerSettingsScreen({Key? key}) : super(key: key);

  @override
  State<SellerSettingsScreen> createState() => _SellerSettingsScreenState();
}

class _SellerSettingsScreenState extends State<SellerSettingsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  void _showAboutDialog() {
    if (!mounted) {
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Về chúng tôi'),
        content: const Text('Food Delivery App'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditProfile(Map<String, dynamic> userData) async {
    bool? updated;
    try {
      updated = await Navigator.push<bool>(
        context,
        MaterialPageRoute<bool>(
          builder: (_) => EditProfileScreen(userData: userData),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở màn chỉnh sửa: $e')),
        );
      }
      return;
    }

    if (!mounted) {
      return;
    }

    if (updated == true) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật thông tin cửa hàng.')),
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn chắc chắn muốn đăng xuất khỏi Seller Panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Cài đặt'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Shop info section
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('users').doc(userId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    color: Colors.white,
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Không tải được thông tin cửa hàng: ${snapshot.error}',
                    ),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const SizedBox.shrink();
                }

                final data = snapshot.data?.data();
                final name = data?['name'] ?? 'Cửa hàng';
                final email = data?['email'] ?? 'email@example.com';
                final phone = data?['phone'] ?? 'Chưa có';
                final userData = data ?? <String, dynamic>{};

                return Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin cửa hàng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Tên cửa hàng', name),
                      _buildInfoRow('Email', email),
                      _buildInfoRow('Số điện thoại', phone),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _openEditProfile(userData),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Chỉnh sửa thông tin',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Settings section
            Container(
              color: Colors.white,
              margin: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  _buildSettingTile(
                    Icons.info_outlined,
                    'Về chúng tôi',
                    'Thông tin ứng dụng & cập nhật ảnh đại diện',
                    onTap: _showAboutDialog,
                  ),
                ],
              ),
            ),

            // Logout section
            Container(
              color: Colors.white,
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất Seller Panel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      ),
      trailing: const Icon(
        Icons.arrow_forward,
        size: 18,
        color: AppTheme.textSecondary,
      ),
      onTap: onTap ?? () {},
    );
  }
}
