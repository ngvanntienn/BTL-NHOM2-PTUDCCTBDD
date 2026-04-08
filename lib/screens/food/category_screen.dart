import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../models/food_model.dart';
import '../../theme/app_theme.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({
    super.key,
    this.initialCategory,
    this.onlyTrending = false,
  });

  final String? initialCategory;
  final bool onlyTrending;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String _selectedCategory = 'Tất cả';

  int _ratingGroup(double rating) {
    if (rating >= 4) return 0;
    if (rating >= 1) return 1;
    return 2;
  }

  int _compareByRatingPriority(FoodModel a, FoodModel b) {
    final int groupDiff = _ratingGroup(a.rating).compareTo(_ratingGroup(b.rating));
    if (groupDiff != 0) return groupDiff;

    final int ratingDiff = b.rating.compareTo(a.rating);
    if (ratingDiff != 0) return ratingDiff;

    final String aName = a.name.trim().toLowerCase();
    final String bName = b.name.trim().toLowerCase();
    return aName.compareTo(bName);
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null && widget.initialCategory!.trim().isNotEmpty) {
      _selectedCategory = widget.initialCategory!.trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.onlyTrending ? 'Món đang thịnh hành' : 'Danh mục món ăn'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('foods')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          final List<FoodModel> allFoods = snapshot.data?.docs
                  .map(FoodModel.fromDoc)
                  .toList() ??
              <FoodModel>[];
          allFoods.sort(_compareByRatingPriority);
          final List<FoodModel> trendingFoods = allFoods
              .where((food) => food.isTrending)
              .toList();
          final List<FoodModel> foods = widget.onlyTrending
              ? (trendingFoods.isEmpty ? allFoods : trendingFoods)
              : allFoods;

          if (foods.isEmpty) {
            return _EmptyFoodsState(onlyTrending: widget.onlyTrending);
          }

          final Set<String> categorySet = foods
              .map((food) => food.category.trim().isEmpty ? 'Khác' : food.category.trim())
              .toSet();
          final List<String> categories = <String>['Tất cả', ...categorySet.toList()..sort()];

          if (!categories.contains(_selectedCategory)) {
            _selectedCategory = 'Tất cả';
          }

          final List<FoodModel> filteredFoods = _selectedCategory == 'Tất cả'
              ? foods
              : foods.where((food) => food.category.trim() == _selectedCategory).toList();

          return Column(
            children: <Widget>[
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemBuilder: (context, index) {
                    final String category = categories[index];
                    final bool selected = category == _selectedCategory;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = category),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? AppTheme.primaryColor : AppTheme.dividerColor,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            category,
                            style: TextStyle(
                              color: selected ? Colors.white : AppTheme.textPrimary,
                              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: categories.length,
                ),
              ),
              Expanded(
                child: filteredFoods.isEmpty
                    ? const _EmptyCategoryState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemBuilder: (context, index) {
                          final FoodModel food = filteredFoods[index];
                          return _FoodListTile(food: food);
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemCount: filteredFoods.length,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FoodListTile extends StatelessWidget {
  const _FoodListTile({required this.food});

  final FoodModel food;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.foodDetail,
          arguments: FoodDetailRouteArgs(foodId: food.id),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 84,
                height: 84,
                child: food.imageUrl.isNotEmpty
                    ? Image.network(
                        food.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _foodImageFallback(),
                      )
                    : _foodImageFallback(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    food.name.trim().isEmpty ? 'Món chưa đặt tên' : food.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    food.restaurant.isEmpty ? 'FoodExpress' : food.restaurant,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        food.rating == 0 ? 'Mới' : food.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '${food.price.toStringAsFixed(0)}đ',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _foodImageFallback() {
    return Container(
      color: const Color(0xFFF0F0F0),
      child: const Icon(Icons.fastfood_rounded, color: Colors.grey, size: 32),
    );
  }
}

class _EmptyFoodsState extends StatelessWidget {
  const _EmptyFoodsState({required this.onlyTrending});

  final bool onlyTrending;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.no_food_rounded, size: 68, color: AppTheme.textSecondary),
          const SizedBox(height: 12),
          Text(
            onlyTrending ? 'Chưa có món thịnh hành' : 'Chưa có dữ liệu món ăn',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            onlyTrending
                ? 'Hãy đánh dấu isTrending=true cho món trên Firestore.'
                : 'Hãy thêm document trong collection foods trên Firestore.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _EmptyCategoryState extends StatelessWidget {
  const _EmptyCategoryState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Icon(Icons.search_off_rounded, size: 62, color: AppTheme.textSecondary),
          SizedBox(height: 10),
          Text(
            'Không có món phù hợp danh mục này',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
