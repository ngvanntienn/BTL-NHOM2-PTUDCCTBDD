import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  // Get users by role
  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch users by role: $e');
    }
  }

  // Update user
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Disable user account
  Future<void> disableUser(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'isDisabled': true});
    } catch (e) {
      throw Exception('Failed to disable user: $e');
    }
  }

  // Enable user account
  Future<void> enableUser(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'isDisabled': false});
    } catch (e) {
      throw Exception('Failed to enable user: $e');
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // Search users
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final allUsers = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();

      return allUsers
          .where((user) =>
              user.name.toLowerCase().contains(query.toLowerCase()) ||
              user.email.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  // Get count of users
  Future<int> getUserCount() async {
    try {
      final snapshot = await _firestore.collection('users').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get user count: $e');
    }
  }

  // Get active users (last 7 days)
  Future<int> getActiveUsersCount() async {
    try {
      final sevenDaysAgo =
          DateTime.now().subtract(const Duration(days: 7));
      final snapshot = await _firestore
          .collection('users')
          .where('lastActive', isGreaterThanOrEqualTo: sevenDaysAgo)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get active users count: $e');
    }
  }
}
