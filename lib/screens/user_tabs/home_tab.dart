import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../models/food_model.dart';
import '../../theme/app_theme.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, this.onSeeAll, this.onCategorySelected});

  final VoidCallback? onSeeAll;
  final ValueChanged<String>? onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Hôm nay bạn muốn ăn gì?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Kham pha mon ngon theo danh muc va xu huong',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              _searchBox(),
              const SizedBox(height: 20),
              _promoBanner(),
              const SizedBox(height: 24),
              _sectionHeader(
                title: 'Danh muc noi bat',
                actionText: 'Xem tất cả',
                onTap: onSeeAll,
              ),
              const SizedBox(height: 12),
              _categoryGrid(onCategorySelected: onCategorySelected),
              const SizedBox(height: 24),
              _sectionHeader(
                title: 'Món đang thịnh hành',
                actionText: 'Xem tất cả',
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.category,
                    arguments: const CategoryRouteArgs(onlyTrending: true),
                  );
                },
              ),
              const SizedBox(height: 12),
              _trendingList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchBox() {
    return GestureDetector(
      onTap: onSeeAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: const Row(
          children: <Widget>[
            Icon(Icons.search, color: AppTheme.textSecondary),
            SizedBox(width: 10),
            Text(
              'Tìm món ăn, quán ăn...',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _promoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFD32027), Color(0xFF8B0000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'ƯU ĐÃI HÔM NAY',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Giảm tới 50%\ncho món ăn hot',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.local_offer, color: Colors.white70, size: 64),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required String actionText,
    VoidCallback? onTap,
  }) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        TextButton(onPressed: onTap, child: Text(actionText)),
      ],
    );
  }

  Widget _categoryGrid({ValueChanged<String>? onCategorySelected}) {
    final List<_CategoryItem> categories = <_CategoryItem>[
      const _CategoryItem('Com', Icons.rice_bowl_outlined),
      const _CategoryItem('Bun & Pho', Icons.ramen_dining_outlined),
      const _CategoryItem('Tra sua', Icons.local_cafe_outlined),
      const _CategoryItem('Pizza', Icons.local_pizza_outlined),
      const _CategoryItem('Snack', Icons.cookie_outlined),
      const _CategoryItem('Healthy', Icons.eco_outlined),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: categories.length,
      itemBuilder: (_, int index) {
        final _CategoryItem item = categories[index];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onCategorySelected?.call(item.name),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(item.icon, color: AppTheme.primaryColor),
                const SizedBox(height: 6),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _trendingList() {
    const int maxTrendingOnHome = 10;
    const int fetchLimit = 120;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('foods')
          .orderBy('rating', descending: true)
          .limit(fetchLimit)
          .snapshots(),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
          ) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final List<FoodModel> foods =
                snapshot.data?.docs
                    .map(FoodModel.fromDoc)
                    .where((FoodModel e) => e.available)
                    .toList() ??
                <FoodModel>[];

            foods.sort(
              (FoodModel a, FoodModel b) => b.rating.compareTo(a.rating),
            );

            if (foods.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Chưa có dữ liệu món ăn.')),
              );
            }

            final List<FoodModel> trendingFoods = foods
                .where((FoodModel food) => food.isTrending)
                .toList();

            final Set<String> trendingIds = trendingFoods
                .map((FoodModel food) => food.id)
                .toSet();
            final List<FoodModel> fallbackFoods = foods
                .where((FoodModel food) => !trendingIds.contains(food.id))
                .toList();

            final List<FoodModel> mergedFoods = <FoodModel>[
              ...trendingFoods,
              ...fallbackFoods,
            ];
            final List<FoodModel> showing = mergedFoods
                .take(maxTrendingOnHome)
                .toList();

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: showing.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, int i) {
                final FoodModel food = showing[i];
                return InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.foodDetail,
                      arguments: FoodDetailRouteArgs(foodId: food.id),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Row(
                      children: <Widget>[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 70,
                            height: 70,
                            child: food.imageUrl.isNotEmpty
                                ? Image.network(
                                    food.imageUrl,
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.low,
                                    cacheWidth: 280,
                                  )
                                : Container(
                                    color: const Color(0xFFF2F2F2),
                                    child: const Icon(Icons.fastfood),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                food.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                food.category,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    food.rating == 0
                                        ? 'Moi'
                                        : food.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${food.price.toStringAsFixed(0)}d',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
    );
  }
}

class _CategoryItem {
  const _CategoryItem(this.name, this.icon);

  final String name;
  final IconData icon;
}
