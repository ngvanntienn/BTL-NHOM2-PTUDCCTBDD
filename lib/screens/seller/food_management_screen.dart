import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/seller/food_model.dart';
import '../../repositories/food_repository.dart';
import '../../theme/app_theme.dart';
import 'add_edit_food_screen.dart';

class FoodManagementScreen extends StatefulWidget {
  const FoodManagementScreen({super.key});

  @override
  State<FoodManagementScreen> createState() => _FoodManagementScreenState();
}

class _FoodManagementScreenState extends State<FoodManagementScreen> {
  final FoodRepository _foodRepository = FoodRepository();

  Future<void> _deleteFood(FoodModel food) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xóa món ăn'),
          content: Text('Bạn có chắc chắn muốn xóa "${food.name}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _foodRepository.deleteFood(food.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã xóa món ăn')));
  }

  @override
  Widget build(BuildContext context) {
    final String sellerId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý món ăn')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const AddEditFoodScreen()),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm món'),
      ),
      body: sellerId.isEmpty
          ? const Center(child: Text('Không tìm thấy tài khoản người bán.'))
          : StreamBuilder<List<FoodModel>>(
              stream: _foodRepository.streamSellerFoods(sellerId),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<FoodModel>> snapshot,
                  ) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Lỗi tải dữ liệu: ${snapshot.error}'),
                      );
                    }

                    final List<FoodModel> foods =
                        snapshot.data ?? <FoodModel>[];
                    if (foods.isEmpty) {
                      return const Center(
                        child: Text(
                          'Chưa có món ăn nào. Bấm "Thêm món" để bắt đầu.',
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: foods.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (BuildContext context, int index) {
                        final FoodModel food = foods[index];
                        final bool available =
                            food.isAvailable && food.stock > 0;

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.dividerColor),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: food.imageUrl.isEmpty
                                  ? Container(
                                      width: 56,
                                      height: 56,
                                      color: AppTheme.backgroundColor,
                                      child: const Icon(Icons.fastfood),
                                    )
                                  : Image.network(
                                      food.imageUrl,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            title: Text(
                              food.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${food.price.toStringAsFixed(0)} VND  •  Tồn: ${food.stock}  •  ${available ? 'Đang bán' : 'Tạm ẩn'}',
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (String value) async {
                                if (value == 'edit') {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          AddEditFoodScreen(food: food),
                                    ),
                                  );
                                } else if (value == 'toggle') {
                                  await _foodRepository.setAvailability(
                                    foodId: food.id,
                                    isAvailable: !food.isAvailable,
                                    stock: food.stock,
                                  );
                                } else if (value == 'delete') {
                                  await _deleteFood(food);
                                }
                              },
                              itemBuilder: (_) => <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Text('Sửa'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'toggle',
                                  child: Text(
                                    food.isAvailable ? 'Ẩn món' : 'Hiện món',
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text('Xóa'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
            ),
    );
  }
}
