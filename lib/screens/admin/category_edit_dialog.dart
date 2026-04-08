import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/category_service.dart';
import '../../models/category_model.dart';

class CategoryEditDialog extends StatefulWidget {
  final CategoryModel? category;
  final Function(CategoryModel) onSave;

  const CategoryEditDialog({
    super.key,
    required this.category,
    required this.onSave,
  });

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _imageUrlController;
  bool _isSaving = false;
  final CategoryService _categoryService = CategoryService();

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController = TextEditingController(text: widget.category!.name);
      _imageUrlController =
          TextEditingController(text: widget.category!.imageUrl);
    } else {
      _nameController = TextEditingController();
      _imageUrlController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên danh mục'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.category != null) {
        // UPDATE: Create updated category with same ID
        final updatedCategory = widget.category!.copyWith(
          name: _nameController.text,
          imageUrl: _imageUrlController.text,
        );

        // Call onSave with updated object (screen handles persistence)
        if (mounted) {
          widget.onSave(updatedCategory);
          Navigator.pop(context);
        }

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật danh mục thành công'),
              backgroundColor: AppTheme.accentColor,
            ),
          );
        }
      } else {
        // ADD: Create new category with generated ID (screen will replace after Firestore)
        final newCategory = CategoryModel(
          categoryId: '', // Empty - will be set by screen
          name: _nameController.text,
          imageUrl: _imageUrlController.text,
          createdAt: DateTime.now(),
        );

        // Call onSave with new object (screen handles persistence)
        if (mounted) {
          widget.onSave(newCategory);
          Navigator.pop(context);
        }

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thêm danh mục thành công'),
              backgroundColor: AppTheme.accentColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null
          ? 'Thêm danh mục'
          : 'Chỉnh sửa danh mục'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên danh mục',
                hintText: 'Nhập tên danh mục',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'URL ảnh',
                hintText: 'Nhập URL ảnh đại diện',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            if (_imageUrlController.text.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                  ),
                  child: Image.network(
                    _imageUrlController.text,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(
                      child: Icon(Icons.broken_image,
                          color: AppTheme.textSecondary),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}
