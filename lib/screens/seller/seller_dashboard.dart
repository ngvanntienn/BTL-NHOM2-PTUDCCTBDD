import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/firestore_schema.dart';
import '../../theme/app_theme.dart';
import 'add_edit_food_screen.dart';
import 'food_management_screen.dart';
import 'order_management_screen.dart';
import 'seller_interview_game_screen.dart';
import 'seller_ranking_screen.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({Key? key}) : super(key: key);

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> _loadHeader(String userId) async {
    final DocumentSnapshot<Map<String, dynamic>> userSnap = await _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .get();
    return userSnap.data() ?? <String, dynamic>{};
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Bảng điều khiển Cửa hàng'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.emoji_events_outlined,
              color: AppTheme.textPrimary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const SellerRankingScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: _loadHeader(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }

                final Map<String, dynamic> userData =
                    snapshot.data ?? <String, dynamic>{};
                final shopName = userData['name'] ?? 'Cửa hàng của tôi';

                return Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chào, $shopName!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Quản lý món ăn, đơn hàng, xếp hạng và doanh thu thưởng theo thời gian thực',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _firestore
                    .collection(FirestoreCollections.foods)
                    .where('sellerId', isEqualTo: userId)
                    .snapshots(),
                builder: (context, foodSnapshot) {
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _firestore
                        .collection(FirestoreCollections.orders)
                        .where('sellerId', isEqualTo: userId)
                        .snapshots(),
                    builder: (context, orderSnapshot) {
                      if (foodSnapshot.connectionState ==
                              ConnectionState.waiting ||
                          orderSnapshot.connectionState ==
                              ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                      foods =
                          foodSnapshot.data?.docs ??
                          <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                      final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                      orders =
                          orderSnapshot.data?.docs ??
                          <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                      final int totalFoods = foods.length;
                      final int activeFoods = foods.where((doc) {
                        final data = doc.data();
                        final bool isAvailable =
                            (data['isAvailable'] as bool?) ?? false;
                        final int stock = (data['stock'] as num?)?.toInt() ?? 0;
                        return isAvailable && stock > 0;
                      }).length;

                      final int outOfStock = foods.where((doc) {
                        final int stock =
                            (doc.data()['stock'] as num?)?.toInt() ?? 0;
                        return stock <= 0;
                      }).length;

                      final int pendingOrders = orders.where((doc) {
                        final String status = (doc.data()['status'] ?? '')
                            .toString();
                        return status == FirestoreOrderStatus.pending;
                      }).length;

                      final double deliveredRevenue = orders.fold<double>(0, (
                        sum,
                        doc,
                      ) {
                        final data = doc.data();
                        final String status = (data['status'] ?? '').toString();
                        if (status != FirestoreOrderStatus.delivered) {
                          return sum;
                        }
                        return sum +
                            ((data['totalPrice'] as num?)?.toDouble() ?? 0);
                      });

                      return StreamBuilder<
                        DocumentSnapshot<Map<String, dynamic>>
                      >(
                        stream: _firestore
                            .collection(FirestoreCollections.users)
                            .doc(userId)
                            .snapshots(),
                        builder: (context, userSnapshot) {
                          final Map<String, dynamic> userData =
                              userSnapshot.data?.data() ?? <String, dynamic>{};
                          final double bonusRevenue =
                              (userData['bonusRevenue'] as num?)?.toDouble() ??
                              0;
                          final double totalRevenue =
                              deliveredRevenue + bonusRevenue;

                          return Column(
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _statCard(
                                      title: 'Tổng món',
                                      value: '$totalFoods',
                                      icon: Icons.restaurant_menu,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _statCard(
                                      title: 'Đang bán',
                                      value: '$activeFoods',
                                      icon: Icons.visibility,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _statCard(
                                      title: 'Hết hàng',
                                      value: '$outOfStock',
                                      icon: Icons.inventory_2_outlined,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _statCard(
                                      title: 'Đơn chờ xử lý',
                                      value: '$pendingOrders',
                                      icon: Icons.pending_actions,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _statCard(
                                      title: 'Doanh thu đơn',
                                      value:
                                          '${deliveredRevenue.toStringAsFixed(0)} VND',
                                      icon: Icons.payments,
                                      color: Colors.teal,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _statCard(
                                      title: 'Doanh thu thưởng',
                                      value:
                                          '${bonusRevenue.toStringAsFixed(0)} VND',
                                      icon: Icons.card_giftcard,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _statCard(
                                title: 'Tổng doanh thu hiển thị',
                                value: '${totalRevenue.toStringAsFixed(0)} VND',
                                icon: Icons.account_balance_wallet,
                                color: AppTheme.primaryColor,
                                fullWidth: true,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hành động nhanh',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _actionCard(
                          icon: Icons.fastfood_outlined,
                          title: 'Quản lý món',
                          subtitle: 'CRUD + tự ẩn hết hàng',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const FoodManagementScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionCard(
                          icon: Icons.receipt_long_outlined,
                          title: 'Xử lý đơn hàng',
                          subtitle: 'Accept / Reject / Update',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const OrderManagementScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _actionCard(
                          icon: Icons.add_business_outlined,
                          title: 'Thêm món mới',
                          subtitle: 'Upload ảnh + lưu Firestore',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const AddEditFoodScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionCard(
                          icon: Icons.quiz_outlined,
                          title: 'Phỏng vấn seller',
                          subtitle: 'Làm bài + lưu realtime',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const SellerInterviewGameScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _actionCard(
                    icon: Icons.emoji_events_outlined,
                    title: 'Xếp hạng & thưởng doanh thu',
                    subtitle: 'Bảng xếp hạng + thưởng ngày/tuần/tháng',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const SellerRankingScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: AppTheme.primaryColor, size: 24),
            const SizedBox(height: 8),
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
    );
  }
}
