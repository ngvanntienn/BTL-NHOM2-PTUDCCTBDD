import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/seller/food_model.dart';
import '../../models/seller/order_model.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/food_repository.dart';
import '../../repositories/order_repository.dart';
import '../seller/food_management_screen.dart';
import '../seller/order_management_screen.dart';
import '../../theme/app_theme.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  final FoodRepository _foodRepository = FoodRepository();
  final OrderRepository _orderRepository = OrderRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();

  @override
  void initState() {
    super.initState();
    _categoryRepository.ensureDefaultCategories();
  }

  @override
  Widget build(BuildContext context) {
    final String sellerId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bảng điều khiển người bán',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.textPrimary),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: sellerId.isEmpty
          ? const Center(child: Text('Không tìm thấy tài khoản người bán.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.amber,
                    child: Icon(
                      Icons.storefront,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Trang quản lý cửa hàng',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Quản lý món ăn, đơn hàng và doanh thu theo thời gian thực',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<List<FoodModel>>(
                    stream: _foodRepository.streamSellerFoods(sellerId),
                    builder:
                        (
                          BuildContext context,
                          AsyncSnapshot<List<FoodModel>> foodSnapshot,
                        ) {
                          return StreamBuilder<List<OrderModel>>(
                            stream: _orderRepository.streamSellerOrders(
                              sellerId,
                            ),
                            builder:
                                (
                                  BuildContext context,
                                  AsyncSnapshot<List<OrderModel>> orderSnapshot,
                                ) {
                                  final List<FoodModel> foods =
                                      foodSnapshot.data ?? <FoodModel>[];
                                  final List<OrderModel> orders =
                                      orderSnapshot.data ?? <OrderModel>[];

                                  final int availableFoods = foods
                                      .where(
                                        (FoodModel e) =>
                                            e.isAvailable && e.stock > 0,
                                      )
                                      .length;
                                  final int pendingOrders = orders
                                      .where(
                                        (OrderModel e) =>
                                            e.status == OrderStatus.pending,
                                      )
                                      .length;
                                  final double revenue = orders
                                      .where(
                                        (OrderModel e) =>
                                            e.status == OrderStatus.delivered,
                                      )
                                      .fold<double>(
                                        0,
                                        (double p, OrderModel e) =>
                                            p + e.totalPrice,
                                      );

                                  return Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      _statCard(
                                        title: 'Tổng món',
                                        value: '${foods.length}',
                                        icon: Icons.inventory_2,
                                      ),
                                      _statCard(
                                        title: 'Đang bán',
                                        value: '$availableFoods',
                                        icon: Icons.visibility,
                                      ),
                                      _statCard(
                                        title: 'Đơn chờ xử lý',
                                        value: '$pendingOrders',
                                        icon: Icons.pending_actions,
                                      ),
                                      _statCard(
                                        title: 'Doanh thu',
                                        value:
                                            '${revenue.toStringAsFixed(0)} VND',
                                        icon: Icons.payments,
                                      ),
                                    ],
                                  );
                                },
                          );
                        },
                  ),
                  const SizedBox(height: 24),
                  _buildFeatureCard(
                    context,
                    'Quản lý món ăn',
                    'Thêm, sửa, xóa, cập nhật tồn kho và ẩn/hiện món',
                    Icons.inventory_2_outlined,
                    Colors.amber,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const FoodManagementScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    context,
                    'Quản lý đơn hàng',
                    'Nhận, cập nhật trạng thái, từ chối và theo dõi thời gian thực',
                    Icons.receipt_long,
                    AppTheme.accentColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const OrderManagementScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
