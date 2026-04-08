import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import 'user_edit_dialog.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'all';

  @override
  void initState() {
    super.initState();
    _reloadData();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when screen comes back into focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadData();
    });
  }

  Future<void> _reloadData() async {
    if (mounted) {
      await Provider.of<UserProvider>(context, listen: false).loadUsers();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Compute filtered list dynamically based on current search & role
  List<UserModel> _getFilteredUsers(List<UserModel> allUsers) {
    final query = _searchController.text.toLowerCase();
    return allUsers.where((user) {
      final matchesSearch = user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
      final matchesRole =
          _selectedRole == 'all' || user.role == _selectedRole;
      return matchesSearch && matchesRole;
    }).toList();
  }

  void _showUserDialog(UserModel? user) {
    showDialog(
      context: context,
      builder: (context) => UserEditDialog(
        user: user,
        onSave: (updatedUser) {
          // Update via provider - will notify all listeners
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.updateUserOptimistically(updatedUser);
        },
      ),
    );
  }

  Future<void> _deleteUser(String userId, String userName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa tài khoản "$userName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              
              try {
                // Optimistic delete
                userProvider.deleteUserOptimistically(userId);

                // Delete from Firestore
                await userProvider.deleteUser(userId);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa tài khoản'),
                      backgroundColor: AppTheme.accentColor,
                    ),
                  );
                }
              } catch (e) {
                // Reload to get latest data if error
                if (mounted) {
                  await userProvider.loadUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Quản lý Tài khoản',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên hoặc email...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            child: const Icon(Icons.clear, color: AppTheme.textSecondary),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                // Role filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      return Row(
                        children: [
                          _buildRoleChip('all', 'Tất cả'),
                          _buildRoleChip('user', 'Khách hàng'),
                          _buildRoleChip('seller', 'Bán hàng'),
                          _buildRoleChip('admin', 'Quản trị'),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                // Dynamically compute filtered list based on provider data + search/role
                final filteredUsers = _getFilteredUsers(userProvider.allUsers);
                
                if (userProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                // Pull-to-refresh wrapper
                return RefreshIndicator(
                  onRefresh: _reloadData,
                  backgroundColor: AppTheme.cardColor,
                  color: AppTheme.primaryColor,
                  child: filteredUsers.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 100),
                                  Icon(Icons.people_outline,
                                      size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                                  const SizedBox(height: 16),
                                  Text('Không tìm thấy tài khoản',
                                      style: Theme.of(context).textTheme.bodyMedium),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return _buildUserCard(user);
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String value, String label) {
    final isSelected = _selectedRole == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedRole = value);
        },
        selectedColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.isDisabled ? Colors.redAccent.withOpacity(0.3) : AppTheme.dividerColor,
          width: user.isDisabled ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Icon(
                  _getRoleIcon(user.role),
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(user.email,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: user.isDisabled 
                      ? Colors.redAccent.withOpacity(0.1)
                      : _getRoleColor(user.role).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  user.isDisabled ? 'Bị khóa' : _getRoleLabel(user.role),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: user.isDisabled ? Colors.redAccent : _getRoleColor(user.role),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('${user.phone} • ${user.address}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showUserDialog(user),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Sửa'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _deleteUser(user.userId, user.name),
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Xóa'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'seller':
        return Icons.store;
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'seller':
        return Colors.orange;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Quản trị';
      case 'seller':
        return 'Bán hàng';
      default:
        return 'Khách hàng';
    }
  }
}
