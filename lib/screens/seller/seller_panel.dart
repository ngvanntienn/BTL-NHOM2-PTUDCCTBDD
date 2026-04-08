import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'seller_dashboard.dart';
import 'seller_voucher_screen.dart';
import 'order_management_screen.dart';
import 'seller_settings_screen.dart';

class SellerPanel extends StatefulWidget {
  const SellerPanel({Key? key}) : super(key: key);

  @override
  State<SellerPanel> createState() => _SellerPanelState();
}

class _SellerPanelState extends State<SellerPanel> {
  int _selectedIndex = 0;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const SellerDashboard(),
      const SellerVoucherScreen(),
      const OrderManagementScreen(),
      const SellerSettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Bảng điều khiển',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_outlined),
            activeIcon: Icon(Icons.local_offer),
            label: 'Voucher',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Đơn hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}
