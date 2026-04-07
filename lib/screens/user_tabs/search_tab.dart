import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_routes.dart';
import '../../models/food_model.dart';
import '../../theme/app_theme.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _controller = TextEditingController();
  String _selectedFilter = 'Gần tôi';
  String _query = '';

  final List<String> _filters = ['Gần tôi', 'Đánh giá cao', 'Giá thấp-cao', 'Nhanh nhất'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<FoodModel> _applyFilters(List<FoodModel> input) {
    final String q = _query.trim().toLowerCase();
    List<FoodModel> list = input;

    if (q.isNotEmpty) {
      list = list.where((food) {
        return food.name.toLowerCase().contains(q) ||
            food.category.toLowerCase().contains(q) ||
            food.restaurant.toLowerCase().contains(q);
      }).toList();
    }

    if (_selectedFilter == 'Đánh giá cao') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_selectedFilter == 'Giá thấp-cao') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_selectedFilter == 'Nhanh nhất') {
      list.sort((a, b) => a.name.length.compareTo(b.name.length));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Khám phá & Tìm kiếm'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('foods').snapshots(),
        builder: (context, snapshot) {
          final List<FoodModel> allFoods = snapshot.data?.docs
                  .map(FoodModel.fromDoc)
                  .toList() ??
              <FoodModel>[];
          final List<FoodModel> foods = _applyFilters(List<FoodModel>.from(allFoods));
          final List<String> categories = allFoods
              .map((food) => food.category.trim())
              .where((category) => category.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextField(
                  controller: _controller,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Tìm món ăn, quán ăn...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                            onPressed: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                          )
                        : const Icon(Icons.mic_none, color: AppTheme.primaryColor),
                  ),
                ),
              ),
              Container(
                color: Colors.white,
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final selected = _filters[i] == _selectedFilter;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = _filters[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? AppTheme.primaryColor : AppTheme.dividerColor,
                          ),
                        ),
                        child: Text(
                          _filters[i],
                          style: TextStyle(
                            color: selected ? Colors.white : AppTheme.textPrimary,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1, color: AppTheme.dividerColor),
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryColor),
                      )
                    : _query.isEmpty
                        ? _buildDiscover(categories, foods)
                        : _buildFoodResults(foods),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDiscover(List<String> categories, List<FoodModel> foods) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Danh mục món',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final category = categories[i];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.category,
                  arguments: CategoryRouteArgs(initialCategory: category),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.category_outlined, color: AppTheme.primaryColor, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 22),
          const Text('Danh sách món nổi bật',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          _buildFoodResults(foods.take(8).toList(), emptyText: 'Chưa có món nào trong Firestore.'),
        ],
      ),
    );
  }

  Widget _buildFoodResults(List<FoodModel> foods, {String emptyText = ''}) {
    if (foods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              emptyText.isEmpty ? 'Không tìm thấy món phù hợp cho "$_query".' : emptyText,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.6),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: foods.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final food = foods[i];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.foodDetail,
            arguments: FoodDetailRouteArgs(foodId: food.id),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: food.imageUrl.isNotEmpty
                        ? Image.network(
                            food.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imageFallback(),
                          )
                        : _imageFallback(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(food.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(food.category,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(food.rating == 0 ? 'Mới' : food.rating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      )
                    ],
                  ),
                ),
                Text(
                  '${food.price.toStringAsFixed(0)}đ',
                  style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _imageFallback() {
    return Container(
      color: const Color(0xFFF2F2F2),
      child: const Icon(Icons.fastfood_rounded, color: Colors.grey, size: 28),
    );
  }
}
