import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';
import 'edit_profile_screen.dart';
import 'order_history_screen.dart';
import 'favorites_screen.dart';
import 'voucher_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  bool _notifEnabled = true;
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final doc = await _db.collection('users').doc(uid).get();
    if (mounted) {
      setState(() {
        _userData = doc.data();
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ', style: TextStyle(color: AppTheme.textSecondary))),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
      }
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buổi sáng';
    if (h < 18) return 'Buổi chiều';
    return 'Buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Hồ sơ của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: _loadUser,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 8),
                    _buildOrdersSection(),
                    const SizedBox(height: 8),
                    _buildUtilitiesSection(),
                    const SizedBox(height: 8),
                    _buildSupportSection(),
                    const SizedBox(height: 24),
                    _buildLogoutButton(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Profile Header ───────────────────────────────────────────────────
  Widget _buildProfileHeader() {
    final name   = _userData?['name'] ?? 'Chưa cập nhật';
    final email  = _userData?['email'] ?? _auth.currentUser?.email ?? '';
    final phone  = _userData?['phone'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    backgroundImage: (_userData?['avatar'] != null &&
                            (_userData!['avatar'] as String).isNotEmpty)
                        ? NetworkImage(_userData!['avatar'] as String)
                        : null,
                    child: (_userData?['avatar'] == null ||
                            (_userData!['avatar'] as String).isEmpty)
                        ? Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _goEditProfile(),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_greeting()}, 👋',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text(email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    if (phone != null && (phone as String).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(phone as String,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _goEditProfile,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Chỉnh sửa thông tin cá nhân'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
              side: const BorderSide(color: AppTheme.primaryColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _goEditProfile() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(userData: _userData ?? {})),
    );
    if (updated == true) _loadUser();
  }

  // ── Orders Section ───────────────────────────────────────────────────
  Widget _buildOrdersSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('MY ORDERS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                      letterSpacing: 1, color: AppTheme.textSecondary)),
              TextButton(
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
                child: const Text('Xem tất cả >',
                    style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Real-time order counts
          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('orders')
                .where('userId', isEqualTo: _auth.currentUser?.uid)
                .snapshots(),
            builder: (context, snap) {
              final orders = snap.data?.docs ?? [];
              int pending   = orders.where((o) => (o.data() as Map)['status'] == 'pending').length;
              int delivering = orders.where((o) => (o.data() as Map)['status'] == 'delivering').length;
              int completed  = orders.where((o) => (o.data() as Map)['status'] == 'completed').length;
              int cancelled  = orders.where((o) => (o.data() as Map)['status'] == 'cancelled').length;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _orderIcon(Icons.pending_outlined,      'Chờ xác nhận', pending,    onTap: () => _goOrders('pending')),
                  _orderIcon(Icons.delivery_dining,       'Đang giao',    delivering,  onTap: () => _goOrders('delivering')),
                  _orderIcon(Icons.check_circle_outline,  'Thành công',   completed,  onTap: () => _goOrders('completed')),
                  _orderIcon(Icons.cancel_outlined,       'Đã hủy',       cancelled,  onTap: () => _goOrders('cancelled')),
                ],
              );
            },
          ),
          const Divider(height: 28, color: AppTheme.dividerColor),
          GestureDetector(
            onTap: () => _goOrders('completed'),
            child: Row(
              children: const [
                Icon(Icons.refresh_rounded, color: AppTheme.primaryColor, size: 20),
                SizedBox(width: 10),
                Text('Đặt lại đơn gần nhất',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goOrders(String filter) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => OrderHistoryScreen(initialFilter: filter)));
  }

  Widget _orderIcon(IconData icon, String label, int count, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppTheme.textPrimary, size: 26),
              ),
              if (count > 0)
                Positioned(
                  top: -4, right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor, shape: BoxShape.circle),
                    child: Text('$count',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Utilities ────────────────────────────────────────────────────────
  Widget _buildUtilitiesSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          _menuTile(Icons.favorite_border_rounded, 'Món ăn yêu thích',
              'Quán ăn & món đã thả tim', onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const FavoritesScreen()))),
          _menuTile(Icons.account_balance_wallet_outlined, 'Ví & Khuyến mãi',
              'Mã giảm giá, Voucher của bạn', onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const VoucherScreen()))),
          _menuTile(Icons.location_on_outlined, 'Địa chỉ giao hàng',
              'Quản lý danh sách địa chỉ', onTap: () {}),
          _menuTile(Icons.payment_outlined, 'Phương thức thanh toán',
              'Thêm & quản lý thẻ ngân hàng', onTap: () {}),
        ],
      ),
    );
  }

  // ── Support & Settings ───────────────────────────────────────────────
  Widget _buildSupportSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          // Notification toggle
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.notifications_active_outlined, color: AppTheme.primaryColor, size: 20),
            ),
            title: const Text('Thông báo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
            subtitle: const Text('Bật/tắt chuông & khuyến mãi',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            trailing: Switch(
              value: _notifEnabled,
              activeColor: AppTheme.primaryColor,
              onChanged: (v) => setState(() => _notifEnabled = v),
            ),
          ),
          _menuTile(Icons.headset_mic_outlined, 'Trợ giúp & CSKH',
              'Liên hệ báo cáo sự cố', onTap: () => _showHelpDialog()),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Trung tâm hỗ trợ', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            ListTile(
              leading: Icon(Icons.phone, color: AppTheme.primaryColor),
              title: Text('Hotline'),
              subtitle: Text('1800-FOOD (18:00 - 22:00)'),
            ),
            ListTile(
              leading: Icon(Icons.email, color: AppTheme.primaryColor),
              title: Text('Email'),
              subtitle: Text('support@foodexpress.vn'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng', style: TextStyle(color: AppTheme.primaryColor))),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          label: const Text('Đăng xuất',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.redAccent, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  Widget _menuTile(IconData icon, String title, String sub, {VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }
}
