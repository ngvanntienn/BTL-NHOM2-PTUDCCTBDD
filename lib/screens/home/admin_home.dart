import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/app_theme.dart';
import '../admin/category_management_screen.dart';
import '../admin/store_management_screen.dart';
import '../admin/system_statistics_screen.dart';
import '../admin/user_management_screen.dart';
import '../login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const <Widget>[
    _AdminDashboardPage(),
    UserManagementScreen(),
    CategoryManagementScreen(),
    StoreManagementScreen(),
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Bang dieu khien quan tri'),
        actions: <Widget>[
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) => setState(() => _currentIndex = index),
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondary,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Người dùng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
            label: 'Danh muc',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined),
            activeIcon: Icon(Icons.store),
            label: 'Cua hang',
          ),
        ],
      ),
    );
  }
}

class _AdminDashboardPage extends StatelessWidget {
  const _AdminDashboardPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Tong quan quan tri',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Quản lý tài khoản, danh mục, cửa hàng và thống kê hệ thống',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          _card(
            context,
            title: 'Quản lý người dùng',
            subtitle: 'Thêm, sửa, xóa, vô hiệu hóa tài khoản',
            icon: Icons.people_outline,
            color: Colors.redAccent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const UserManagementScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _card(
            context,
            title: 'Quản lý danh mục',
            subtitle: 'CRUD danh muc + dong bo Firestore realtime',
            icon: Icons.category_outlined,
            color: Colors.blueAccent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const CategoryManagementScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _card(
            context,
            title: 'Quản lý cửa hàng',
            subtitle: 'Duyet, kich hoat, khoa seller',
            icon: Icons.store_outlined,
            color: Colors.orangeAccent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const StoreManagementScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _card(
            context,
            title: 'Thống kê hệ thống',
            subtitle: 'Tổng đơn, doanh thu, người dùng hoạt động',
            icon: Icons.analytics_outlined,
            color: Colors.purpleAccent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const SystemStatisticsScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.14),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }
}

