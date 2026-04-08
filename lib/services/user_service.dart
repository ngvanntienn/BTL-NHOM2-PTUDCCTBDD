import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/user_model.dart';

enum DeleteUserOutcome { fullSync, firestoreOnly }

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'asia-southeast1',
  );

  Future<void> _deleteByQuery(Query<Map<String, dynamic>> query) async {
    while (true) {
      final QuerySnapshot<Map<String, dynamic>> snap = await query
          .limit(200)
          .get();
      if (snap.docs.isEmpty) {
        return;
      }

      final WriteBatch batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _deleteSubcollection(
    CollectionReference<Map<String, dynamic>> ref,
  ) async {
    while (true) {
      final QuerySnapshot<Map<String, dynamic>> snap = await ref
          .limit(200)
          .get();
      if (snap.docs.isEmpty) {
        return;
      }

      final WriteBatch batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _deleteUserDataFirestoreOnly(String userId) async {
    await _deleteByQuery(
      _firestore.collection('foods').where('sellerId', isEqualTo: userId),
    );
    await _deleteByQuery(
      _firestore.collection('orders').where('userId', isEqualTo: userId),
    );
    await _deleteByQuery(
      _firestore.collection('orders').where('sellerId', isEqualTo: userId),
    );
    await _deleteByQuery(
      _firestore
          .collection('seller_interview_attempts')
          .where('sellerId', isEqualTo: userId),
    );
    await _deleteByQuery(
      _firestore
          .collection('seller_rewards')
          .where('sellerId', isEqualTo: userId),
    );

    await _deleteSubcollection(
      _firestore.collection('users').doc(userId).collection('addresses'),
    );
    await _deleteSubcollection(
      _firestore.collection('favorites').doc(userId).collection('items'),
    );

    await _firestore
        .collection('favorites')
        .doc(userId)
        .delete()
        .catchError((_) {});
    await _firestore
        .collection('users')
        .doc(userId)
        .delete()
        .catchError((_) {});
  }

  // Get all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .get()
          .timeout(const Duration(seconds: 12));
      final List<UserModel> users = <UserModel>[];
      for (final doc in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();
        data['userId'] ??= doc.id;
        try {
          users.add(UserModel.fromMap(data));
        } catch (e) {
          print('Skip malformed user doc ${doc.id}: $e');
        }
      }
      return users;
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final Map<String, dynamic> data = doc.data()!;
        data['userId'] ??= doc.id;
        return UserModel.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  // Get users by role - Filter in code
  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .get()
          .timeout(const Duration(seconds: 12));

      final List<UserModel> users = <UserModel>[];
      for (final doc in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();
        data['userId'] ??= doc.id;
        try {
          users.add(UserModel.fromMap(data));
        } catch (_) {}
      }

      return users.where((user) => user.role == role).toList();
    } catch (e) {
      print('Error fetching users by role: $e');
      return [];
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
      await _firestore.collection('users').doc(userId).update({
        'isDisabled': true,
      });
    } catch (e) {
      throw Exception('Failed to disable user: $e');
    }
  }

  // Enable user account
  Future<void> enableUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isDisabled': false,
      });
    } catch (e) {
      throw Exception('Failed to enable user: $e');
    }
  }

  // Delete user
  Future<DeleteUserOutcome> deleteUser(String userId) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable(
        'adminDeleteUserCascade',
      );

      final HttpsCallableResult<dynamic> result = await callable.call(
        <String, dynamic>{'userId': userId},
      );

      final dynamic data = result.data;
      final bool ok = data is Map && data['ok'] == true;
      if (!ok) {
        throw Exception('Cloud Function trả về kết quả không hợp lệ.');
      }
      return DeleteUserOutcome.fullSync;
    } on FirebaseFunctionsException catch (e) {
      if (<String>{
        'internal',
        'unavailable',
        'not-found',
        'unimplemented',
        'deadline-exceeded',
      }.contains(e.code)) {
        await _deleteUserDataFirestoreOnly(userId);
        return DeleteUserOutcome.firestoreOnly;
      }

      throw Exception(
        'Xóa tài khoản thất bại (${e.code}): ${e.message ?? 'Lỗi không xác định'}',
      );
    } catch (e) {
      try {
        await _deleteUserDataFirestoreOnly(userId);
        return DeleteUserOutcome.firestoreOnly;
      } catch (_) {
        throw Exception('Failed to delete user: $e');
      }
    }
  }

  // Search users
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .get()
          .timeout(const Duration(seconds: 12));
      final List<UserModel> allUsers = <UserModel>[];
      for (final doc in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();
        data['userId'] ??= doc.id;
        try {
          allUsers.add(UserModel.fromMap(data));
        } catch (_) {}
      }

      return allUsers
          .where(
            (user) =>
                user.name.toLowerCase().contains(query.toLowerCase()) ||
                user.email.toLowerCase().contains(query.toLowerCase()),
          )
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
      // Return 0 if collection doesn't exist
      return 0;
    }
  }

  // Get count of managed accounts shown in admin user list (exclude admin role)
  Future<int> getManagedUserCount() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.where((doc) {
        final String role = (doc.data()['role'] ?? '').toString();
        return role != 'admin';
      }).length;
    } catch (e) {
      return 0;
    }
  }

  // Active managed users: non-admin and not disabled
  Future<int> getManagedActiveUsersCount() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.where((doc) {
        final Map<String, dynamic> data = doc.data();
        final String role = (data['role'] ?? '').toString();
        final bool isDisabled = (data['isDisabled'] as bool?) ?? false;
        return role != 'admin' && !isDisabled;
      }).length;
    } catch (e) {
      return 0;
    }
  }

  // Get active users (last 7 days) - Filter in code to avoid missing fields
  Future<int> getActiveUsersCount() async {
    try {
      final snapshot = await _firestore.collection('users').get();

      if (snapshot.docs.isEmpty) {
        return 0;
      }

      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      // Filter in code - check if lastActive exists and is recent
      int count = 0;
      for (var doc in snapshot.docs) {
        final lastActive = doc.data()['lastActive'];
        if (lastActive != null) {
          final lastActiveDate = (lastActive as Timestamp).toDate();
          if (lastActiveDate.isAfter(sevenDaysAgo)) {
            count++;
          }
        }
      }
      return count;
    } catch (e) {
      // Return 0 if error
      print('Error getting active users: $e');
      return 0;
    }
  }
}
