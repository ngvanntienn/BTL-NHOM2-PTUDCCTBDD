import 'package:flutter/material.dart';
import '../user_tabs/home_tab.dart';
import '../user_tabs/search_tab.dart';
import '../user_tabs/cart_tab.dart';
import '../user_tabs/profile_tab.dart';
import '../user_tabs/chatbot_screen.dart';
import '../../theme/app_theme.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeTab(),
    SearchTab(),
    CartTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatbotScreen()),
        ),
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
