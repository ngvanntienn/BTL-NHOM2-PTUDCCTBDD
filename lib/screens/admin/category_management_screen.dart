import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/category_provider.dart';
import '../../models/category_model.dart';
import 'category_edit_dialog.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

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
      await Provider.of<CategoryProvider>(context, listen: false).loadCategories();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Compute filtered categories dynamically
  List<CategoryModel> _getFilteredCategories(List<CategoryModel> allCategories) {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return allCategories;
    return allCategories.where((category) {
      return category.name.toLowerCase().contains(query);
    }).toList();
  }

  void _showCategoryDialog(CategoryModel? category) {
    showDialog(
      context: context,
      builder: (context) => CategoryEditDialog(
        category: category,
        onSave: (updatedCategory) async {
          final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
          try {
            if (category != null) {
              // UPDATE: Optimistic update first
              print('[CategoryManagement] UPDATE optimistic for ${category.categoryId}');
              categoryProvider.updateCategoryOptimistically(updatedCategory);
              
              // Then persist to Firestore  
              await categoryProvider.updateCategory(category.categoryId, {
                'name': updatedCategory.name,
                'imageUrl': updatedCategory.imageUrl,
              });
              print('[CategoryManagement] UPDATE persisted successfully');
            } else {
              // ADD: Optimistic add first with temp ID
              final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
              final tempCategory = updatedCategory.copyWith(categoryId: tempId);
              
              print('[CategoryManagement] ADD optimistic with temp ID: $tempId');
              categoryProvider.addCategoryOptimistically(tempCategory);
              
              // Then persist to Firestore and get real ID
              final realId = await categoryProvider.createCategory(tempCategory);
              print('[CategoryManagement] ADD persisted with real ID: $realId');
              
              // Provider already replaced temp with real ID internally,
              // but ensure it's correct by updating
              final realCategory = updatedCategory.copyWith(categoryId: realId);
              categoryProvider.updateCategoryOptimistically(realCategory);
            }
          } catch (e) {
            print('[CategoryManagement] Error: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Lỗi: $e'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _deleteCategory(String categoryId, String categoryName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content:
            Text('Bạn có chắc chắn muốn xóa danh mục "$categoryName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              
              final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
              
              try {
                // Optimistic delete
                categoryProvider.deleteCategoryOptimistically(categoryId);

                // Delete from Firestore
                await categoryProvider.deleteCategory(categoryId);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa danh mục'),
                      backgroundColor: AppTheme.accentColor,
                    ),
                  );
                }
              } catch (e) {
                // Reload to get latest data if error
                if (mounted) {
                  await categoryProvider.loadCategories();
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
        title: const Text('Quản lý Danh mục Món ăn',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(null),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Thêm danh mục'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm danh mục...',
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
          ),
          Expanded(
            child: Consumer<CategoryProvider>(
              builder: (context, categoryProvider, child) {
                // Dynamically compute filtered list based on provider data + search
                final filteredCategories = _getFilteredCategories(categoryProvider.allCategories);
                
                if (categoryProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                // Pull-to-refresh wrapper
                return RefreshIndicator(
                  onRefresh: _reloadData,
                  backgroundColor: AppTheme.cardColor,
                  color: AppTheme.primaryColor,
                  child: filteredCategories.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 100),
                                  Icon(Icons.category_outlined,
                                      size: 64,
                                      color: AppTheme.textSecondary.withOpacity(0.5)),
                                  const SizedBox(height: 16),
                                  Text('Không tìm thấy danh mục',
                                      style: Theme.of(context).textTheme.bodyMedium),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredCategories.length,
                          itemBuilder: (context, index) {
                            final category = filteredCategories[index];
                            return _buildCategoryCard(category);
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

  Widget _buildCategoryCard(CategoryModel category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                  ),
                  child: category.imageUrl.isNotEmpty
                      ? Image.network(
                          category.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.image_not_supported,
                                  color: AppTheme.textSecondary),
                        )
                      : Icon(
                          Icons.category,
                          color: AppTheme.primaryColor,
                          size: 40,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${category.foodCount} sản phẩm',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showCategoryDialog(category),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Sửa'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _deleteCategory(category.categoryId, category.name),
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
}
