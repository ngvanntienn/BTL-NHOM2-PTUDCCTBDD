import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService = CategoryService();
  
  List<CategoryModel> _allCategories = [];
  bool _isLoading = false;

  // Getters
  List<CategoryModel> get allCategories => _allCategories;
  bool get isLoading => _isLoading;

  // Load all categories
  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _allCategories = await _categoryService.getAllCategories();
      notifyListeners();
    } catch (e) {
      print('Error loading categories: $e');
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add category optimistically
  void addCategoryOptimistically(CategoryModel newCategory) {
    print('[CategoryProvider] addCategoryOptimistically - name: ${newCategory.name}, categoryId: ${newCategory.categoryId}');
    // Add even if categoryId is empty (temp ID), will be replaced later
    _allCategories.add(newCategory);
    print('[CategoryProvider] Category added to list (${_allCategories.length} total), notifying listeners');
    notifyListeners();
  }

  // Update category optimistically
  void updateCategoryOptimistically(CategoryModel updatedCategory) {
    final index = _allCategories.indexWhere((c) => c.categoryId == updatedCategory.categoryId);
    print('[CategoryProvider] updateCategoryOptimistically - categoryId: ${updatedCategory.categoryId}, index: $index');
    if (index >= 0) {
      _allCategories[index] = updatedCategory;
      print('[CategoryProvider] Category updated at index $index, notifying listeners');
      notifyListeners();
    } else {
      print('[CategoryProvider] Category not found!');
    }
  }

  // Delete category optimistically
  void deleteCategoryOptimistically(String categoryId) {
    _allCategories.removeWhere((c) => c.categoryId == categoryId);
    notifyListeners();
  }

  Future<String> createCategory(CategoryModel category) async {
    try {
      // Assume category is already added to list optimistically (called from screen)
      print('[CategoryProvider] createCategory called with categoryId: ${category.categoryId}');
      
      // Persist to Firestore (categoryId in category object is ignored)
      final docId = await _categoryService.createCategory(
        CategoryModel(
          categoryId: '',
          name: category.name,
          imageUrl: category.imageUrl,
          createdAt: category.createdAt,
        ),
      );
      
      print('[CategoryProvider] Firestore returned real ID: $docId');
      
      // Replace temp category with real one if it exists
      if (category.categoryId.startsWith('temp_')) {
        final tempIndex = _allCategories.indexWhere((c) => c.categoryId == category.categoryId);
        if (tempIndex >= 0) {
          print('[CategoryProvider] Replacing temp ID at index $tempIndex');
          _allCategories[tempIndex] = category.copyWith(categoryId: docId);
          notifyListeners();
        }
      }
      
      return docId;
    } catch (e) {
      // Remove failed temp category
      if (category.categoryId.startsWith('temp_')) {
        _allCategories.removeWhere((c) => c.categoryId == category.categoryId);
        notifyListeners();
      }
      print('Error creating category: $e');
      rethrow;
    }
  }

  // Update category (optimistic update)
  Future<void> updateCategory(String categoryId, Map<String, dynamic> data) async {
    try {
      // Find category
      final index = _allCategories.indexWhere((c) => c.categoryId == categoryId);
      if (index < 0) return;
      
      // Store original for rollback
      final original = _allCategories[index];
      
      // 1. Optimistic update
      final updated = original.copyWith(
        name: data['name'] ?? original.name,
        imageUrl: data['imageUrl'] ?? original.imageUrl,
      );
      _allCategories[index] = updated;
      notifyListeners();
      
      // 2. Update in Firestore
      await _categoryService.updateCategory(categoryId, data);
    } catch (e) {
      // Reload to ensure consistency on error
      await loadCategories();
      print('Error updating category: $e');
      rethrow;
    }
  }

  // Delete category (optimistic update)
  Future<void> deleteCategory(String categoryId) async {
    try {
      // 1. Optimistic delete
      _allCategories.removeWhere((c) => c.categoryId == categoryId);
      notifyListeners();
      
      // 2. Delete from Firestore
      await _categoryService.deleteCategory(categoryId);
    } catch (e) {
      // Reload on error to ensure consistency
      await loadCategories();
      print('Error deleting category: $e');
      rethrow;
    }
  }

  // Search categories
  List<CategoryModel> searchCategories(String query) {
    if (query.isEmpty) return _allCategories;
    
    return _allCategories
        .where((category) => 
            category.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
