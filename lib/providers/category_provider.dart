import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService = CategoryService();

  List<CategoryModel> _allCategories = [];
  bool _isLoading = false;

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

  // Getters
  List<CategoryModel> get allCategories => _allCategories;
  bool get isLoading => _isLoading;

  // Load all categories
  Future<void> loadCategories() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _safeNotifyListeners();

    try {
      _allCategories = await _categoryService.getAllCategories();
    } catch (e) {
      print('Error loading categories: $e');
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Add category optimistically
  void addCategoryOptimistically(CategoryModel newCategory) {
    // Add even if categoryId is empty (temp ID), will be replaced later
    _allCategories.add(newCategory);
    _safeNotifyListeners();
  }

  // Update category optimistically
  void updateCategoryOptimistically(CategoryModel updatedCategory) {
    final index = _allCategories.indexWhere(
      (c) => c.categoryId == updatedCategory.categoryId,
    );
    if (index >= 0) {
      _allCategories[index] = updatedCategory;
      _safeNotifyListeners();
    }
  }

  // Delete category optimistically
  void deleteCategoryOptimistically(String categoryId) {
    _allCategories.removeWhere((c) => c.categoryId == categoryId);
    _safeNotifyListeners();
  }

  Future<String> createCategory(CategoryModel category) async {
    try {
      // Assume category is already added to list optimistically (called from screen)

      // Persist to Firestore (categoryId in category object is ignored)
      final docId = await _categoryService.createCategory(
        CategoryModel(
          categoryId: '',
          name: category.name,
          imageUrl: category.imageUrl,
          createdAt: category.createdAt,
        ),
      );

      // Replace temp category with real one if it exists
      if (category.categoryId.startsWith('temp_')) {
        final tempIndex = _allCategories.indexWhere(
          (c) => c.categoryId == category.categoryId,
        );
        if (tempIndex >= 0) {
          _allCategories[tempIndex] = category.copyWith(categoryId: docId);
          _safeNotifyListeners();
        }
      }

      return docId;
    } catch (e) {
      // Remove failed temp category
      if (category.categoryId.startsWith('temp_')) {
        _allCategories.removeWhere((c) => c.categoryId == category.categoryId);
        _safeNotifyListeners();
      }
      print('Error creating category: $e');
      rethrow;
    }
  }

  // Update category (optimistic update)
  Future<void> updateCategory(
    String categoryId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Find category
      final index = _allCategories.indexWhere(
        (c) => c.categoryId == categoryId,
      );
      if (index < 0) return;

      // Store original for rollback
      final original = _allCategories[index];

      // 1. Optimistic update
      final updated = original.copyWith(
        name: data['name'] ?? original.name,
        imageUrl: data['imageUrl'] ?? original.imageUrl,
      );
      _allCategories[index] = updated;
      _safeNotifyListeners();

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
      _safeNotifyListeners();

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
        .where(
          (category) =>
              category.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }
}
