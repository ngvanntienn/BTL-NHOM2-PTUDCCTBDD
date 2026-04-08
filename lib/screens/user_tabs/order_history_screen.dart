import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../utils/money_utils.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key, this.initialFilter = 'all'});

  final String initialFilter;

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late String _filter;

  final List<String> _filters = <String>[
    'all',
    'pending',
    'delivering',
    'completed',
    'cancelled',
  ];

  final List<String> _labels = <String>[
    'Tất cả',
    'Đang chờ',
    'Đang giao',
    'Thành công',
    'Đã hủy',
  ];

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
      case 'accepted':
      case 'preparing':
        return Colors.orange;
      case 'delivering':
      case 'shipping':
        return Colors.blue;
      case 'completed':
      case 'delivered':
        return AppTheme.accentColor;
      case 'cancelled':
      case 'rejected':
        return Colors.redAccent;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Đang chờ';
      case 'accepted':
      case 'preparing':
        return 'Đang chuẩn bị';
      case 'delivering':
      case 'shipping':
        return 'Đang giao';
      case 'completed':
      case 'delivered':
        return 'Đã giao';
      case 'cancelled':
      case 'rejected':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
      case 'accepted':
      case 'preparing':
        return Icons.pending_outlined;
      case 'delivering':
      case 'shipping':
        return Icons.delivery_dining;
      case 'completed':
      case 'delivered':
        return Icons.check_circle_outline;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.receipt_outlined;
    }
  }

  bool _matchesFilter(String status) {
    if (_filter == 'all') {
      return true;
    }

    if (_filter == 'pending') {
      return status == 'pending' ||
          status == 'accepted' ||
          status == 'preparing';
    }

    if (_filter == 'delivering') {
      return status == 'delivering' || status == 'shipping';
    }

    if (_filter == 'completed') {
      return status == 'completed' || status == 'delivered';
    }

    if (_filter == 'cancelled') {
      return status == 'cancelled' || status == 'rejected';
    }

    return status == _filter;
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    final Stream<QuerySnapshot<Map<String, dynamic>>> stream = FirebaseFirestore
        .instance
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
        children: <Widget>[
          Container(
            color: Colors.white,
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, int i) {
                final bool selected = _filter == _filters[i];
                return GestureDetector(
                  onTap: () => setState(() => _filter = _filters[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primaryColor
                            : AppTheme.dividerColor,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _labels[i],
                        style: TextStyle(
                          color: selected ? Colors.white : AppTheme.textPrimary,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppTheme.dividerColor),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  );
                }

                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 48,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Không thể tải đơn hàng',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snap.error}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
                    snap.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                docs = docs.where((doc) {
                  final String status = (doc.data()['status'] ?? 'pending')
                      .toString();
                  return _matchesFilter(status);
                }).toList();

                if (docs.isEmpty) {
                  return _emptyState();
                }

                docs.sort((a, b) {
                  final Timestamp? tA = a.data()['createdAt'] as Timestamp?;
                  final Timestamp? tB = b.data()['createdAt'] as Timestamp?;
                  if (tA == null && tB == null) {
                    return 0;
                  }
                  if (tA == null) {
                    return 1;
                  }
                  if (tB == null) {
                    return -1;
                  }
                  return tB.compareTo(tA);
                });

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, int i) => _orderCard(docs[i]),
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
        children: <Widget>[
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có đơn hàng nào',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Các đơn hàng của bạn sẽ hiển thị ở đây',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _orderCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data();
    final String status = (data['status'] ?? 'pending').toString();
    final List<dynamic> items =
        (data['items'] as List<dynamic>?) ?? <dynamic>[];
    final double total =
        (data['total'] as num?)?.toDouble() ??
        (data['totalPrice'] as num?)?.toDouble() ??
        0.0;
    final DateTime? date = (data['createdAt'] as Timestamp?)?.toDate();

    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );

    final String dateStr = date != null
        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}'
        : '--';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => OrderDetailScreen(orderId: doc.id),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    '#${doc.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          _statusIcon(status),
                          color: _statusColor(status),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _statusLabel(status),
                          style: TextStyle(
                            color: _statusColor(status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                dateStr,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            const Divider(
              height: 20,
              indent: 16,
              endIndent: 16,
              color: AppTheme.dividerColor,
            ),
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Column(
                  children: items.take(3).map((dynamic raw) {
                    final Map<String, dynamic> item =
                        raw is Map<String, dynamic>
                        ? raw
                        : Map<String, dynamic>.from(raw as Map);
                    final int quantity =
                        (item['quantity'] as num?)?.toInt() ?? 1;
                    final String productName =
                        (item['productName'] ?? item['foodName'] ?? 'Món ăn')
                            .toString();
                    final double unitPrice =
                        (item['price'] as num?)?.toDouble() ??
                        (item['unitPrice'] as num?)?.toDouble() ??
                        0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '× $quantity  $productName',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            MoneyUtils.formatVnd(
                              currencyFormat,
                              unitPrice * quantity,
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            if (items.length > 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Text(
                  '+ ${items.length - 3} món khác',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            const Divider(
              height: 20,
              indent: 16,
              endIndent: 16,
              color: AppTheme.dividerColor,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Tổng: ${MoneyUtils.formatVnd(currencyFormat, total)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.primaryColor,
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
}
