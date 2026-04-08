import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all orders - Handle empty collection
  Future<List<OrderModel>> getAllOrders() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return [];
      }
      
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      // Return empty list if collection doesn't exist
      if (e.toString().contains('no document') || 
          e.toString().contains('not exist') ||
          e.toString().contains('NOT_FOUND')) {
        return [];
      }
      throw Exception('Failed to fetch orders: $e');
    }
  }

  // Get orders by status - Filter in code to avoid index issues
  Future<List<OrderModel>> getOrdersByStatus(String status) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();
      
      final filtered = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data()))
          .where((order) => order.status == status)
          .toList();
      return filtered;
    } catch (e) {
      throw Exception('Failed to fetch orders by status: $e');
    }
  }

  // Get orders by date range - Filter in code
  Future<List<OrderModel>> getOrdersByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();
      
      final filtered = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data()))
          .where((order) =>
              order.createdAt.isAfter(startDate) &&
              order.createdAt.isBefore(endDate.add(const Duration(days: 1))))
          .toList();
      return filtered;
    } catch (e) {
      throw Exception('Failed to fetch orders by date range: $e');
    }
  }

  // Get total revenue - Filter in code
  Future<double> getTotalRevenue() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();
      
      double total = 0;
      for (var doc in snapshot.docs) {
        final order = OrderModel.fromMap(doc.data());
        if (order.status == 'delivered') {
          total += order.totalPrice;
        }
      }
      return total;
    } catch (e) {
      throw Exception('Failed to get total revenue: $e');
    }
  }

  // Get revenue by date range - Filter in code
  Future<double> getRevenueByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();
      
      double total = 0;
      for (var doc in snapshot.docs) {
        final order = OrderModel.fromMap(doc.data());
        if (order.status == 'delivered' &&
            order.createdAt.isAfter(startDate) &&
            order.createdAt.isBefore(endDate.add(const Duration(days: 1)))) {
          total += order.totalPrice;
        }
      }
      return total;
    } catch (e) {
      throw Exception('Failed to get revenue by date range: $e');
    }
  }

  // Get order count - Return 0 if collection empty
  Future<int> getOrderCount() async {
    try {
      final snapshot = await _firestore.collection('orders').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      // Return 0 if collection doesn't exist
      return 0;
    }
  }

  // Get pending order count - Filter in code
  Future<int> getPendingOrderCount() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();
      
      final count = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data()))
          .where((order) => order.status == 'pending')
          .length;
      return count;
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
