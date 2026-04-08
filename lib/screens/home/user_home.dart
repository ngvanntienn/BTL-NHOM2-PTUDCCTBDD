import 'package:flutter/material.dart';
import '../../app_routes.dart';
import 'package:provider/provider.dart';
import '../user_tabs/home_tab.dart';
import '../user_tabs/search_tab.dart';
import '../user_tabs/cart_tab.dart';
import '../user_tabs/profile_tab.dart';
import '../user_tabs/chatbot_screen.dart';
import '../user_tabs/notification_screen.dart';
import '../../theme/app_theme.dart';
import '../../providers/notification_provider.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;
  String? _selectedCategory;

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category == 'Thêm' ? null : category;
      _currentIndex = 1; // Chuyển sang Tab Search
    });
  }

  void _onSeeAll() {
    setState(() {
      _selectedCategory = null;
      _currentIndex = 1; // Chuyển sang Tab Search
    });
  }

  List<Widget> get _pages => [
        HomeTab(
          onSeeAll: _onSeeAll,
          onCategorySelected: _onCategorySelected,
        ),
        SearchTab(
          key: ValueKey(_selectedCategory),
          initialCategory: _selectedCategory,
        ),
        const CartTab(),
        const ProfileTab(),
      ];

  @override
  Widget build(BuildContext context) {
    final notifProvider = Provider.of<NotificationProvider>(context);
    final unread = notifProvider.unreadCount;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Food Express',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                fontSize: 20)),
        actions: [
          // 🔔 Chuông thông báo có badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: AppTheme.textPrimary, size: 26),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationScreen()),
                ),
              ),
              if (unread > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.chatbot),
        backgroundColor: AppTheme.primaryColor,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.smart_toy_outlined,
          color: Colors.white,
          size: 26,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        height: 64,
        padding: EdgeInsets.zero,
        elevation: 12,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Trang chủ'),
            _navItem(
              1,
              Icons.search_rounded,
              Icons.search_outlined,
              'Tìm kiếm',
            ),
            const SizedBox(width: 60), // notch space
            _navItem(
              2,
              Icons.shopping_bag_rounded,
              Icons.shopping_bag_outlined,
              'Giỏ hàng',
            ),
            _navItem(
              3,
              Icons.person_rounded,
              Icons.person_outline_rounded,
              'Hồ sơ',
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData activeIcon, IconData icon, String label) {
    final selected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? activeIcon : icon,
              color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
