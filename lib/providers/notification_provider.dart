import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotifType { order, voucher, system }

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotifType type;
  final String? orderId;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.type = NotifType.system,
    this.orderId,
    this.isRead = false,
  });
}

class NotificationProvider with ChangeNotifier {
  final List<NotificationModel> _notifications = [];
  StreamSubscription<QuerySnapshot>? _orderSub;
  final Map<String, String> _lastOrderStatus = {}; // orderId -> previousStatus

  void _safeNotifyListeners() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    final isBuilding =
        phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.transientCallbacks;

    if (isBuilding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) {
          notifyListeners();
        }
      });
      return;
    }

    notifyListeners();
  }

  List<NotificationModel> get notifications =>
      [..._notifications].reversed.toList();

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // ── Thêm thông báo thủ công ──────────────────────────────────────────
  void addNotification({
    required String title,
    required String body,
    NotifType type = NotifType.system,
    String? orderId,
  }) {
    _notifications.add(
      NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        timestamp: DateTime.now(),
        type: type,
        orderId: orderId,
      ),
    );
    _safeNotifyListeners();
  }

  // ── Lắng nghe trạng thái đơn hàng realtime ──────────────────────────
  void startOrderListener(String uid) {
    _orderSub?.cancel();
    _lastOrderStatus.clear();

    _orderSub = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((snap) {
          for (final change in snap.docChanges) {
            final data = change.doc.data() as Map<String, dynamic>?;
            if (data == null) continue;

            final orderId = change.doc.id;
            final status = data['status'] as String? ?? '';
            final shortId = orderId.substring(0, 8).toUpperCase();

            if (change.type == DocumentChangeType.added) {
              // Lưu trạng thái ban đầu, không thông báo khi mới tạo (checkout đã thông báo)
              _lastOrderStatus[orderId] = status;
            } else if (change.type == DocumentChangeType.modified) {
              final prevStatus = _lastOrderStatus[orderId];
              if (prevStatus != null && prevStatus != status) {
                // Trạng thái thay đổi → thêm thông báo
                _lastOrderStatus[orderId] = status;
                final info = _statusInfo(status);
                addNotification(
                  title: '${info['icon']} Đơn hàng #$shortId',
                  body: info['body'] as String,
                  type: NotifType.order,
                  orderId: orderId,
                );
              }
            }
          }
        });
  }

  void stopOrderListener() {
    _orderSub?.cancel();
    _orderSub = null;
    _lastOrderStatus.clear();
  }

  Map<String, String> _statusInfo(String status) {
    switch (status) {
      case 'confirmed':
        return {'icon': '✅', 'body': 'Đơn hàng đã được xác nhận!'};
      case 'delivering':
        return {'icon': '🛵', 'body': 'Tài xế đang trên đường giao hàng!'};
      case 'completed':
        return {'icon': '🎉', 'body': 'Đơn hàng đã giao thành công!'};
      case 'cancelled':
        return {'icon': '❌', 'body': 'Đơn hàng đã bị hủy.'};
      default:
        return {'icon': '📦', 'body': 'Trạng thái đơn: $status'};
    }
  }

  // ── Đọc / Xóa ────────────────────────────────────────────────────────
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      _safeNotifyListeners();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    _safeNotifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    _safeNotifyListeners();
  }

  @override
  void dispose() {
    _orderSub?.cancel();
    super.dispose();
  }
}
