import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  List<UserModel> _allUsers = [];
  bool _isLoading = false;

  void _safeNotifyListeners() {
    final binding = SchedulerBinding.instance;
    final phase = binding.schedulerPhase;
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

  // Getters
  List<UserModel> get allUsers => _allUsers;
  bool get isLoading => _isLoading;

  // Load all users
  Future<void> loadUsers() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _safeNotifyListeners();

    try {
      _allUsers = await _userService.getAllUsers();
    } catch (e) {
      print('Error loading users: $e');
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Get users by role
  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      return await _userService.getUsersByRole(role);
    } catch (e) {
      print('Error fetching users by role: $e');
      return [];
    }
  }

  // Update user optimistically
  void updateUserOptimistically(UserModel updatedUser) {
    final index = _allUsers.indexWhere((u) => u.userId == updatedUser.userId);
    if (index >= 0) {
      _allUsers[index] = updatedUser;
      _safeNotifyListeners();
    }
  }

  // Delete user optimistically
  ({UserModel? removedUser, int removedIndex}) deleteUserOptimistically(
    String userId,
  ) {
    final int index = _allUsers.indexWhere((u) => u.userId == userId);
    UserModel? removed;
    if (index >= 0) {
      removed = _allUsers.removeAt(index);
    }
    _safeNotifyListeners();
    return (removedUser: removed, removedIndex: index);
  }

  void restoreDeletedUser(UserModel user, int index) {
    if (index < 0 || index > _allUsers.length) {
      _allUsers.add(user);
    } else {
      _allUsers.insert(index, user);
    }
    _safeNotifyListeners();
  }

  // Update user in Firestore
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _userService.updateUser(userId, data);
      // Reload to ensure consistency
      await loadUsers();
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // Delete user from Firestore
  Future<DeleteUserOutcome> deleteUser(String userId) async {
    try {
      return await _userService.deleteUser(userId);
      // Optimistic delete already done before calling this
      // Just notify if needed
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  // Disable user (optimistic update)
  Future<void> disableUser(String userId) async {
    // Find user index
    final index = _allUsers.indexWhere((u) => u.userId == userId);
    print('[UserProvider] disableUser - userId: $userId, index: $index');
    if (index < 0) {
      print('[UserProvider] User not found!');
      return;
    }

    // Store original state for rollback
    final originalUser = _allUsers[index];
    print(
      '[UserProvider] Original user: ${originalUser.name}, isDisabled: ${originalUser.isDisabled}',
    );

    try {
      // 1. Optimistic update - update UI immediately
      _allUsers[index] = _allUsers[index].copyWith(isDisabled: true);
      print(
        '[UserProvider] After optimistic update: ${_allUsers[index].name}, isDisabled: ${_allUsers[index].isDisabled}',
      );

      _safeNotifyListeners();
      print('[UserProvider] notifyListeners() called!');

      // 2. Then call Firestore
      await _userService.disableUser(userId);
      print('[UserProvider] Firestore disabled successfully');
    } catch (e) {
      // Rollback on error
      _allUsers[index] = originalUser;
      _safeNotifyListeners();
      print('Error disabling user: $e');
      rethrow;
    }
  }

  // Enable user (optimistic update)
  Future<void> enableUser(String userId) async {
    // Find user index
    final index = _allUsers.indexWhere((u) => u.userId == userId);
    print('[UserProvider] enableUser - userId: $userId, index: $index');
    if (index < 0) {
      print('[UserProvider] User not found!');
      return;
    }

    // Store original state for rollback
    final originalUser = _allUsers[index];
    print(
      '[UserProvider] Original user: ${originalUser.name}, isDisabled: ${originalUser.isDisabled}',
    );

    try {
      // 1. Optimistic update - update UI immediately
      _allUsers[index] = _allUsers[index].copyWith(isDisabled: false);
      print(
        '[UserProvider] After optimistic update: ${_allUsers[index].name}, isDisabled: ${_allUsers[index].isDisabled}',
      );

      _safeNotifyListeners();
      print('[UserProvider] notifyListeners() called!');

      // 2. Then call Firestore
      await _userService.enableUser(userId);
      print('[UserProvider] Firestore enabled successfully');
    } catch (e) {
      // Rollback on error
      _allUsers[index] = originalUser;
      _safeNotifyListeners();
      print('Error enabling user: $e');
      rethrow;
    }
  }
}
