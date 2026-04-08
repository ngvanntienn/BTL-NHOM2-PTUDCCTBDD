import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  final String initialFilter;
  const OrderHistoryScreen({super.key, this.initialFilter = 'all'});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late String _filter;
  final _filters = ['all', 'pending', 'delivering', 'completed', 'cancelled'];
  final _labels  = ['Tất cả', 'Đang chờ', 'Đang giao', 'Thành công', 'Đã hủy'];

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':    return Colors.orange;
      case 'delivering': return Colors.blue;
      case 'completed':  return AppTheme.accentColor;
      case 'cancelled':  return Colors.redAccent;
      default:           return AppTheme.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':    return 'Đang chờ';
      case 'delivering': return 'Đang giao';
      case 'completed':  return 'Đã giao';
      case 'cancelled':  return 'Đã hủy';
      default:           return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':    return Icons.pending_outlined;
      case 'delivering': return Icons.delivery_dining;
      case 'completed':  return Icons.check_circle_outline;
      case 'cancelled':  return Icons.cancel_outlined;
      default:           return Icons.receipt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // Chỉ dùng 1 điều kiện where duy nhất, filter + sort ở client
    final stream = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .snapshots();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Lịch sử đơn hàng'),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: Colors.white,
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final sel = _filter == _filters[i];
                return GestureDetector(
                  onTap: () => setState(() => _filter = _filters[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? AppTheme.primaryColor : AppTheme.dividerColor),
                    ),
                    child: Center(
                      child: Text(_labels[i],
                          style: TextStyle(
                            color: sel ? Colors.white : AppTheme.textPrimary,
                            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          )),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppTheme.dividerColor),

          // Order list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
                          const SizedBox(height: 12),
                          const Text('Không thể tải đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('${snap.error}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }
                var docs = snap.data?.docs ?? [];

                // Filter theo status ở client (không cần Firestore index)
                if (_filter != 'all') {
                  docs = docs.where((d) =>
                    (d.data() as Map)['status'] == _filter
                  ).toList();
                }

                if (docs.isEmpty) return _emptyState();
                // Sắp xếp mới nhất lên trên ở phía client
                final sorted = [...docs]..sort((a, b) {
                  final tA = (a.data() as Map)['createdAt'] as Timestamp?;
                  final tB = (b.data() as Map)['createdAt'] as Timestamp?;
                  if (tA == null && tB == null) return 0;
                  if (tA == null) return 1;
                  if (tB == null) return -1;
                  return tB.compareTo(tA);
                });
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _orderCard(sorted[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('Chưa có đơn hàng nào', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text('Các đơn hàng của bạn sẽ hiển thị ở đây', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _orderCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'pending';
    final items  = (data['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final total  = (data['total'] as num?)?.toDouble() ?? 0.0;
    final date   = (data['createdAt'] as Timestamp?)?.toDate();
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    final dateStr = date != null
        ? '${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2,'0')}'
        : '--';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: doc.id))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('#${doc.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(status), color: _statusColor(status), size: 14),
                        const SizedBox(width: 4),
                        Text(_statusLabel(status),
                            style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(dateStr, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ),

            // Items summary
            const Divider(height: 20, indent: 16, endIndent: 16, color: AppTheme.dividerColor),
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Column(
                  children: items.take(3).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '× ${item['quantity'] ?? 1}  ${item['productName'] ?? 'Món ăn'}',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(currencyFormat.format(((item['price'] as num?)?.toDouble() ?? 0) * (item['quantity'] ?? 1) * 1000),
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            if (items.length > 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Text('+ ${items.length - 3} món khác', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ),

            const Divider(height: 20, indent: 16, endIndent: 16, color: AppTheme.dividerColor),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tổng: ${currencyFormat.format(total * 1000)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryColor)),
                  if (status == 'completed')
                    FilledButton.icon(
                      onPressed: () => _reorder(data),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Đặt lại', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reorder(Map<String, dynamic> orderData) {
    // Tạo đơn hàng mới (clone) từ đơn cũ
    final newOrder = {
      'userId':    FirebaseAuth.instance.currentUser?.uid,
      'items':     orderData['items'],
      'total':     orderData['total'],
      'status':    'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };
    FirebaseFirestore.instance.collection('orders').add(newOrder).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã đặt lại đơn hàng thành công! 🎉'),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        setState(() => _filter = 'pending');
      }
    });
  }
}
