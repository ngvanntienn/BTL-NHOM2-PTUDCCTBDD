import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';

class StoreManagementScreen extends StatefulWidget {
  const StoreManagementScreen({super.key});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'all'; // all, active, blocked

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
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUsers();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Compute filtered sellers dynamically
  List<UserModel> _getFilteredSellers(List<UserModel> allUsers) {
    final query = _searchController.text.toLowerCase();
    return allUsers
        .where((seller) => seller.role == 'seller')
        .where((seller) {
      final matchesSearch = seller.name.toLowerCase().contains(query) ||
          seller.email.toLowerCase().contains(query);
      
      // Filter by status
      bool matchesStatus = true;
      if (_filterStatus == 'active') {
        matchesStatus = !seller.isDisabled;
      } else if (_filterStatus == 'blocked') {
        matchesStatus = seller.isDisabled;
      }
      
      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _toggleStoreStatus(String sellerId, bool currentStatus) async {
    try {
      print('[StoreManagement] _toggleStoreStatus called - sellerId: $sellerId, currentStatus: $currentStatus');
      
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      print('[StoreManagement] UserProvider allUsers count: ${userProvider.allUsers.length}');

      // Toggle status via provider
      if (currentStatus) {
        // Currently blocked, so enable/unblock
        print('[StoreManagement] Enabling user (was disabled)');
        await userProvider.enableUser(sellerId);
      } else {
        // Currently active, so disable/block
        print('[StoreManagement] Disabling user (was active)');
        await userProvider.disableUser(sellerId);
      }

      print('[StoreManagement] Provider update complete');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentStatus ? 'Đã kích hoạt cửa hàng' : 'Đã khóa cửa hàng'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      print('[StoreManagement] Error in _toggleStoreStatus: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showStoreDetails(UserModel seller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chi tiết cửa hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Tên cửa hàng', seller.name),
            _buildDetailRow('Email', seller.email),
            _buildDetailRow('Điện thoại', seller.phone),
            _buildDetailRow('Địa chỉ', seller.address),
            _buildDetailRow('Ngày tạo', _formatDate(seller.createdAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Quản lý Cửa hàng',
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
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm cửa hàng...',
                    prefixIcon:
                        const Icon(Icons.search, color: AppTheme.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            child: const Icon(Icons.clear,
                                color: AppTheme.textSecondary),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusChip('all', 'Tất cả'),
                      _buildStatusChip('active', 'Đang hoạt động'),
                      _buildStatusChip('blocked', 'Bị khóa'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                // Dynamically compute filtered list based on provider data + filters
                final filteredSellers = _getFilteredSellers(userProvider.allUsers);
                print('[StoreManagement] Consumer rebuilt - allUsers: ${userProvider.allUsers.length}, filtered: ${filteredSellers.length}');
                
                if (userProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                // Pull-to-refresh wrapper
                return RefreshIndicator(
                  onRefresh: _reloadData,
                  backgroundColor: AppTheme.cardColor,
                  color: AppTheme.primaryColor,
                  child: filteredSellers.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 100),
                                  Icon(Icons.store_outlined,
                                      size: 64,
                                      color: AppTheme.textSecondary.withOpacity(0.5)),
                                  const SizedBox(height: 16),
                                  Text('Không tìm thấy cửa hàng',
                                      style: Theme.of(context).textTheme.bodyMedium),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredSellers.length,
                          itemBuilder: (context, index) {
                            final seller = filteredSellers[index];
                            return _buildStoreCard(seller);
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

  Widget _buildStatusChip(String value, String label) {
    final isSelected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filterStatus = value);
        },
        selectedColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildStoreCard(UserModel seller) {
    final isBlocked = seller.isDisabled;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBlocked ? Colors.redAccent.withOpacity(0.3) : AppTheme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: const Icon(
                  Icons.store,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(seller.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(seller.email,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isBlocked
                      ? Colors.redAccent.withOpacity(0.1)
                      : AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isBlocked ? 'Bị khóa' : 'Đang hoạt động',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isBlocked ? Colors.redAccent : AppTheme.accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.phone, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(seller.phone,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(width: 16),
              const Icon(Icons.location_on, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(seller.address,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showStoreDetails(seller),
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('Chi tiết'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () =>
                    _toggleStoreStatus(seller.userId, isBlocked),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isBlocked ? AppTheme.accentColor : Colors.redAccent,
                ),
                icon: Icon(isBlocked ? Icons.lock_open : Icons.lock, size: 16),
                label: Text(isBlocked ? 'Kích hoạt' : 'Khóa'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
