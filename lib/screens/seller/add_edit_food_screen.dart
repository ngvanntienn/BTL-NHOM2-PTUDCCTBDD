import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/seller/category_model.dart';
import '../../models/seller/food_model.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/food_repository.dart';
import '../../services/image_upload_service.dart';
import '../../theme/app_theme.dart';

class AddEditFoodScreen extends StatefulWidget {
  const AddEditFoodScreen({super.key, this.food});

  final FoodModel? food;

  @override
  State<AddEditFoodScreen> createState() => _AddEditFoodScreenState();
}

class _AddEditFoodScreenState extends State<AddEditFoodScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  final FoodRepository _foodRepository = FoodRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  final ImageUploadService _imageUploadService = ImageUploadService();

  String? _selectedCategoryId;
  bool _isAvailable = true;
  bool _isSaving = false;
  String _imageUrl = '';
  XFile? _pickedImage;

  bool get _isEdit => widget.food != null;

  @override
  void initState() {
    super.initState();
    final FoodModel? food = widget.food;
    if (food != null) {
      _nameController.text = food.name;
      _descriptionController.text = food.description;
      _priceController.text = food.price.toStringAsFixed(0);
      _stockController.text = food.stock.toString();
      _selectedCategoryId = food.categoryId;
      _isAvailable = food.isAvailable;
      _imageUrl = food.imageUrl;
    } else {
      _stockController.text = '1';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (file == null) {
      return;
    }
    setState(() => _pickedImage = file);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn danh mục.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      String finalImageUrl = _imageUrl;
      if (_pickedImage != null) {
        finalImageUrl = await _imageUploadService.uploadFoodImage(
          _pickedImage!,
        );
      }

      final int stock = int.parse(_stockController.text.trim());
      final bool available = stock > 0 && _isAvailable;
      final DateTime now = DateTime.now();
      final String sellerId = FirebaseAuth.instance.currentUser?.uid ?? '';

      if (sellerId.isEmpty) {
        throw Exception('Bạn cần đăng nhập tài khoản người bán để thao tác.');
      }

      final FoodModel payload = FoodModel(
        id: widget.food?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        imageUrl: finalImageUrl,
        categoryId: _selectedCategoryId!,
        sellerId: sellerId,
        rating: widget.food?.rating ?? 0,
        isAvailable: available,
        stock: stock,
        createdAt: widget.food?.createdAt ?? now,
        updatedAt: now,
      );

      if (_isEdit) {
        await _foodRepository.updateFood(payload);
      } else {
        await _foodRepository.addFood(payload);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'Cập nhật món thành công.' : 'Thêm món thành công.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể lưu món: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Sửa món ăn' : 'Thêm món ăn')),
      body: StreamBuilder<List<CategoryModel>>(
        stream: _categoryRepository.streamCategories(),
        builder:
            (
              BuildContext context,
              AsyncSnapshot<List<CategoryModel>> snapshot,
            ) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Lỗi tải danh mục: ${snapshot.error}'),
                  ),
                );
              }

              final List<CategoryModel> categories =
                  snapshot.data ?? <CategoryModel>[];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.dividerColor),
                            color: Colors.white,
                          ),
                          child: _pickedImage != null
                              ? FutureBuilder<Uint8List>(
                                  future: _pickedImage!.readAsBytes(),
                                  builder: (_, AsyncSnapshot<Uint8List> snap) {
                                    if (!snap.hasData) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.memory(
                                        snap.data!,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  },
                                )
                              : (_imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.network(
                                          _imageUrl,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Icon(
                                              Icons.add_a_photo_outlined,
                                              size: 34,
                                            ),
                                            SizedBox(height: 8),
                                            Text('Chọn ảnh món ăn'),
                                          ],
                                        ),
                                      )),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Tên món'),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nhập tên món';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Mô tả'),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nhập mô tả';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Giá (VND)',
                        ),
                        validator: (String? value) {
                          final double? parsed = double.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Giá không hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Số lượng tồn',
                        ),
                        validator: (String? value) {
                          final int? parsed = int.tryParse(value ?? '');
                          if (parsed == null || parsed < 0) {
                            return 'Số lượng không hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Danh mục',
                        ),
                        items: categories
                            .map(
                              (CategoryModel c) => DropdownMenuItem<String>(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (String? value) {
                          setState(() => _selectedCategoryId = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        value: _isAvailable,
                        onChanged: (bool value) =>
                            setState(() => _isAvailable = value),
                        title: const Text('Hiển thị món cho khách hàng'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _save,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_isEdit ? 'Lưu thay đổi' : 'Thêm món'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
      ),
    );
  }
}
