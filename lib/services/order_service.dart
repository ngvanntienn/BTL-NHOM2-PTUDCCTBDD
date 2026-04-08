import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all orders
  Future<List<OrderModel>> getAllOrders() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  // Get orders by status
  Future<List<OrderModel>> getOrdersByStatus(String status) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch orders by status: $e');
    }
  }

  // Get orders by date range
  Future<List<OrderModel>> getOrdersByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch orders by date range: $e');
    }
  }

  // Get total revenue
  Future<double> getTotalRevenue() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'delivered')
          .get();
      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['totalPrice'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    } catch (e) {
      throw Exception('Failed to get total revenue: $e');
    }
  }

  // Get revenue by date range
  Future<double> getRevenueByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'delivered')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .get();
      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['totalPrice'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    } catch (e) {
      throw Exception('Failed to get revenue by date range: $e');
    }
  }

  // Get order count
  Future<int> getOrderCount() async {
    try {
      final snapshot = await _firestore.collection('orders').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get order count: $e');
    }
  }

  // Get pending order count
  Future<int> getPendingOrderCount() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get pending order count: $e');
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }
}
