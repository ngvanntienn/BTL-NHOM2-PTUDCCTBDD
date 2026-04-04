import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Hồ sơ của tôi'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Avatar and basic info (Profile Management)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Row(
                children: [
                   const CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(0xFFEEEEEE),
                    child: Icon(Icons.person, color: Colors.grey, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Đang lấy dữ liệu...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('email@example.com', style: TextStyle(color: AppTheme.textSecondary)),
                        SizedBox(height: 4),
                        Text('Chỉnh sửa thông tin cá nhân >', style: TextStyle(color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Order History Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Lịch sử đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Xem tất cả >', style: TextStyle(color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionIcon(Icons.pending_actions, 'Đang chờ'),
                      _buildActionIcon(Icons.delivery_dining, 'Đang giao'),
                      _buildActionIcon(Icons.check_circle_outline, 'Thành công'),
                      _buildActionIcon(Icons.cancel_outlined, 'Đã hủy'),
                    ],
                  ),
                  const Divider(height: 32, color: Color(0xFFEEEEEE)),
                  // Reorder quick feature button placeholder
                  Row(
                    children: const [
                      Icon(Icons.refresh, color: AppTheme.primaryColor, size: 20),
                      SizedBox(width: 8),
                      Text('Đặt lại đơn gần nhất', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSecondary),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Utilities Section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Tiện ích', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
            ),
            const SizedBox(height: 12),
            _buildListMenu(Icons.favorite_border, 'Món ăn yêu thích', 'Quán ăn & món ăn đã thả tim'),
            _buildListMenu(Icons.account_balance_wallet_outlined, 'Ví & Khuyến mãi', 'Mã giảm giá, Voucher của bạn'),
            const SizedBox(height: 24),

            // Settings Section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Cài đặt & Hỗ trợ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
            ),
            const SizedBox(height: 12),
            _buildListMenu(Icons.notifications_active_outlined, 'Thông báo (Push Notifications)', 'Cài đặt chuông báo, khuyến mãi'),
            _buildListMenu(Icons.headphones_outlined, 'Trung tâm hỗ trợ', 'Liên hệ CSKH báo cáo lỗi'),
            const SizedBox(height: 32),
            
            // Logout
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Đăng xuất', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFFF0F0F0),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.textPrimary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _buildListMenu(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSecondary),
        onTap: () {},
      ),
    );
  }
}
