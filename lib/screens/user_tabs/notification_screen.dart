import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/notification_provider.dart';
import 'package:intl/intl.dart';
import 'order_detail_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context);
    final notifications = provider.notifications;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Thông báo',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () => provider.markAllAsRead(),
              child: const Text('Đọc hết',
                  style: TextStyle(
                      color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
            ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined,
                color: AppTheme.textSecondary),
            tooltip: 'Xóa tất cả',
            onPressed: () => _confirmClear(context, provider),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? _emptyState()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 72, color: Color(0xFFF0F0F0)),
              itemBuilder: (context, i) => _buildTile(context, notifications[i], provider),
            ),
    );
  }

  Widget _buildTile(
      BuildContext context, NotificationModel n, NotificationProvider provider) {
    final time = _formatTime(n.timestamp);
    final iconData = _iconFor(n.type, n.title);
    final iconColor = _colorFor(n.type, n.isRead);
    final bgColor = _bgColorFor(n.type, n.isRead);

    return InkWell(
      onTap: () {
        provider.markAsRead(n.id);
        // Nếu là thông báo đơn hàng → mở chi tiết
        if (n.type == NotifType.order && n.orderId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => OrderDetailScreen(orderId: n.orderId!)),
          );
        }
      },
      child: Container(
        color: n.isRead ? Colors.transparent : AppTheme.primaryColor.withOpacity(0.04),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            fontWeight:
                                n.isRead ? FontWeight.w500 : FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6, top: 4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.body,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(time,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 11)),
                      if (n.type == NotifType.order && n.orderId != null) ...[
                        const SizedBox(width: 8),
                        Text('Xem đơn →',
                            style: TextStyle(
                                color: AppTheme.primaryColor.withOpacity(0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(NotifType type, String title) {
    if (type == NotifType.voucher || title.contains('Voucher') || title.contains('voucher')) {
      return Icons.local_offer_rounded;
    }
    if (type == NotifType.order) {
      if (title.contains('🛵') || title.contains('giao')) {
        return Icons.delivery_dining;
      }
      if (title.contains('✅') || title.contains('xác nhận')) {
        return Icons.check_circle_outline;
      }
      if (title.contains('🎉') || title.contains('thành công')) {
        return Icons.celebration_outlined;
      }
      if (title.contains('❌') || title.contains('hủy')) {
        return Icons.cancel_outlined;
      }
      return Icons.receipt_long_outlined;
    }
    return Icons.notifications_outlined;
  }

  Color _colorFor(NotifType type, bool isRead) {
    if (isRead) return Colors.grey;
    switch (type) {
      case NotifType.voucher:
        return const Color(0xFFE91E63);
      case NotifType.order:
        return AppTheme.primaryColor;
      default:
        return Colors.blueGrey;
    }
  }

  Color _bgColorFor(NotifType type, bool isRead) {
    if (isRead) return Colors.grey.withOpacity(0.08);
    switch (type) {
      case NotifType.voucher:
        return const Color(0xFFE91E63).withOpacity(0.10);
      case NotifType.order:
        return AppTheme.primaryColor.withOpacity(0.10);
      default:
        return Colors.blueGrey.withOpacity(0.10);
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return DateFormat('HH:mm  dd/MM/yyyy').format(dt);
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: AppTheme.textSecondary.withOpacity(0.2)),
          const SizedBox(height: 20),
          const Text('Không có thông báo nào',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('Thông báo đặt hàng và voucher sẽ hiển thị ở đây',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, NotificationProvider provider) {
    if (provider.notifications.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa thông báo',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc muốn xóa tất cả thông báo không?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Huỷ')),
          FilledButton(
            onPressed: () {
              provider.clearAll();
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xóa hết'),
          ),
        ],
      ),
    );
  }
}
