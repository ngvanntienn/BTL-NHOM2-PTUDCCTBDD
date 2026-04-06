import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/seller/order_model.dart';
import '../../repositories/order_repository.dart';
import '../../theme/app_theme.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final OrderRepository _orderRepository = OrderRepository();
  OrderStatus? _filter;
  final Set<String> _updatingOrderIds = <String>{};

  Future<void> _runOrderAction({
    required String orderId,
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    if (_updatingOrderIds.contains(orderId)) {
      return;
    }

    setState(() => _updatingOrderIds.add(orderId));
    try {
      await action();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Khong the cap nhat don: $e')));
    } finally {
      if (mounted) {
        setState(() => _updatingOrderIds.remove(orderId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String sellerId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý đơn hàng')),
      body: sellerId.isEmpty
          ? const Center(child: Text('Không tìm thấy tài khoản người bán.'))
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: <Widget>[
                        _chip(label: 'Tất cả', status: null),
                        ...OrderStatus.values.map(
                          (OrderStatus e) =>
                              _chip(label: _statusLabel(e), status: e),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<OrderModel>>(
                    stream: _orderRepository.streamSellerOrders(sellerId),
                    builder:
                        (
                          BuildContext context,
                          AsyncSnapshot<List<OrderModel>> snapshot,
                        ) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Lỗi: ${snapshot.error}'),
                            );
                          }

                          List<OrderModel> orders =
                              snapshot.data ?? <OrderModel>[];
                          if (_filter != null) {
                            orders = orders
                                .where((OrderModel e) => e.status == _filter)
                                .toList();
                          }

                          if (orders.isEmpty) {
                            return const Center(
                              child: Text('Không có đơn hàng nào.'),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: orders.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, int index) {
                              final OrderModel order = orders[index];
                              return _orderCard(order);
                            },
                          );
                        },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _chip({required String label, required OrderStatus? status}) {
    final bool selected = _filter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        onSelected: (_) => setState(() => _filter = status),
      ),
    );
  }

  Widget _orderCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Đơn #${order.id.substring(0, 6).toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(order.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(order.status),
                  style: TextStyle(
                    color: _statusColor(order.status),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Khách: ${order.userName} • ${order.userPhone}'),
          const SizedBox(height: 4),
          Text('Địa chỉ: ${order.shippingAddress}'),
          const SizedBox(height: 10),
          Text(
            'Tổng tiền: ${order.totalPrice.toStringAsFixed(0)} VND',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...order.items.map(
            (OrderItemModel item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('- ${item.foodName} x${item.quantity}'),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: _statusActions(order)),
        ],
      ),
    );
  }

  List<Widget> _statusActions(OrderModel order) {
    final bool isUpdating = _updatingOrderIds.contains(order.id);

    switch (order.status) {
      case OrderStatus.pending:
        return <Widget>[
          FilledButton(
            onPressed: isUpdating
                ? null
                : () => _runOrderAction(
                    orderId: order.id,
                    action: () => _orderRepository.acceptOrder(order.id),
                    successMessage: 'Da nhan don thanh cong.',
                  ),
            child: const Text('Nhận đơn'),
          ),
          OutlinedButton(
            onPressed: isUpdating
                ? null
                : () => _runOrderAction(
                    orderId: order.id,
                    action: () => _orderRepository.rejectOrder(order.id),
                    successMessage: 'Da tu choi don.',
                  ),
            child: const Text('Từ chối'),
          ),
        ];
      case OrderStatus.accepted:
        return <Widget>[
          FilledButton(
            onPressed: isUpdating
                ? null
                : () => _runOrderAction(
                    orderId: order.id,
                    action: () => _orderRepository.updateOrderStatus(
                      orderId: order.id,
                      status: OrderStatus.preparing,
                    ),
                    successMessage: 'Don dang o trang thai chuan bi.',
                  ),
            child: const Text('Đang chuẩn bị'),
          ),
        ];
      case OrderStatus.preparing:
        return <Widget>[
          FilledButton(
            onPressed: isUpdating
                ? null
                : () => _runOrderAction(
                    orderId: order.id,
                    action: () => _orderRepository.updateOrderStatus(
                      orderId: order.id,
                      status: OrderStatus.shipping,
                    ),
                    successMessage: 'Don da chuyen sang dang giao.',
                  ),
            child: const Text('Đang giao'),
          ),
        ];
      case OrderStatus.shipping:
        return <Widget>[
          FilledButton(
            onPressed: isUpdating
                ? null
                : () => _runOrderAction(
                    orderId: order.id,
                    action: () => _orderRepository.updateOrderStatus(
                      orderId: order.id,
                      status: OrderStatus.delivered,
                    ),
                    successMessage: 'Don da giao thanh cong.',
                  ),
            child: const Text('Đã giao'),
          ),
        ];
      case OrderStatus.delivered:
      case OrderStatus.rejected:
      case OrderStatus.cancelled:
        return const <Widget>[];
    }
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.deepPurple;
      case OrderStatus.shipping:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.rejected:
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Chờ xử lý';
      case OrderStatus.accepted:
        return 'Đã nhận';
      case OrderStatus.preparing:
        return 'Đang chuẩn bị';
      case OrderStatus.shipping:
        return 'Đang giao';
      case OrderStatus.delivered:
        return 'Đã giao';
      case OrderStatus.rejected:
        return 'Từ chối';
      case OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }
}
