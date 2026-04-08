import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';
import '../../services/order_service.dart';
import '../../services/category_service.dart';

class SystemStatisticsScreen extends StatefulWidget {
  const SystemStatisticsScreen({super.key});

  @override
  State<SystemStatisticsScreen> createState() =>
      _SystemStatisticsScreenState();
}

class _SystemStatisticsScreenState extends State<SystemStatisticsScreen> {
  final UserService _userService = UserService();
  final OrderService _orderService = OrderService();
  final CategoryService _categoryService = CategoryService();

  Future<Map<String, dynamic>> _loadStatistics() async {
    try {
      final totalUsers = await _userService.getUserCount();
      final activeUsers = await _userService.getActiveUsersCount();
      final totalOrders = await _orderService.getOrderCount();
      final pendingOrders = await _orderService.getPendingOrderCount();
      final totalRevenue = await _orderService.getTotalRevenue();
      final categoryCount = await _categoryService.getCategoryCount();

      // Calculate monthly revenue (last 30 days)
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final monthlyRevenue =
          await _orderService.getRevenueByDateRange(thirtyDaysAgo, now);

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'totalOrders': totalOrders,
        'pendingOrders': pendingOrders,
        'totalRevenue': totalRevenue,
        'monthlyRevenue': monthlyRevenue,
        'categoryCount': categoryCount,
      };
    } catch (e) {
      throw Exception('Failed to load statistics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Thống kê Hệ thống',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadStatistics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64,
                      color: AppTheme.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${snapshot.error}'),
                ],
              ),
            );
          }

          final stats = snapshot.data ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                const Text(
                  'Tổng quan Hệ thống',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 24),

                // Key metrics grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _buildStatCard(
                      title: 'Tổng Người dùng',
                      value: '${stats['totalUsers'] ?? 0}',
                      icon: Icons.people_outline,
                      color: Colors.blueAccent,
                    ),
                    _buildStatCard(
                      title: 'Đang Hoạt động',
                      value: '${stats['activeUsers'] ?? 0}',
                      icon: Icons.trending_up,
                      color: AppTheme.accentColor,
                    ),
                    _buildStatCard(
                      title: 'Tổng Đơn hàng',
                      value: '${stats['totalOrders'] ?? 0}',
                      icon: Icons.shopping_bag_outlined,
                      color: Colors.orangeAccent,
                    ),
                    _buildStatCard(
                      title: 'Chờ Xử lý',
                      value: '${stats['pendingOrders'] ?? 0}',
                      icon: Icons.schedule,
                      color: Colors.purpleAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Revenue section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Doanh số',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      _buildRevenueRow(
                        'Doanh số tổng',
                        _formatCurrency(stats['totalRevenue'] as double? ?? 0.0),
                        Colors.blueAccent,
                      ),
                      const SizedBox(height: 16),
                      _buildRevenueRow(
                        'Doanh số 30 ngày',
                        _formatCurrency(stats['monthlyRevenue'] as double? ?? 0.0),
                        AppTheme.accentColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Categories section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.indigoAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.category,
                          color: Colors.indigoAccent,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Danh mục Món ăn',
                              style: TextStyle(
                                  fontSize: 14, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${stats['categoryCount'] ?? 0}',
                              style: const TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Export data button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showExportDialog(stats);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.download),
                    label: const Text('Xuất Báo cáo'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)}₫';
  }

  void _showExportDialog(Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xuất Báo cáo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chọn định dạng:'),
            const SizedBox(height: 16),
            _buildExportButton('📊 Excel', () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tính năng sẽ được thêm trong phiên bản tiếp theo'),
                  backgroundColor: AppTheme.accentColor,
                ),
              );
            }),
            const SizedBox(height: 8),
            _buildExportButton('📄 PDF', () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tính năng sẽ được thêm trong phiên bản tiếp theo'),
                  backgroundColor: AppTheme.accentColor,
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
