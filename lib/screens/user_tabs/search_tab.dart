import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_routes.dart';
import '../../models/food_model.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../theme/app_theme.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  static const int _maxSearchFetch = 150;
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  String _selectedCategory = 'Tất cả';
  String _selectedFilter = 'Lien quan';

  final List<String> _filters = <String>[
    'Lien quan',
    'Danh gia cao',
    'Gia thap-cao',
    'Moi nhat',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null &&
        widget.initialCategory!.trim().isNotEmpty) {
      _selectedCategory = widget.initialCategory!.trim();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Tìm kiếm món ăn'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('foods')
            .orderBy('createdAt', descending: true)
            .limit(_maxSearchFetch)
            .snapshots(),
        builder:
            (
              BuildContext context,
              AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
            ) {
              final List<FoodModel> allFoods =
                  snapshot.data?.docs.map(FoodModel.fromDoc).toList() ??
                  <FoodModel>[];

              final List<String> categories = <String>[
                'Tất cả',
                ...allFoods
                    .map((FoodModel food) => food.category.trim())
                    .where((String cat) => cat.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort(),
              ];

              if (!categories.contains(_selectedCategory)) {
                _selectedCategory = 'Tất cả';
              }

              final List<FoodModel> foods = _applyFilters(
                List<FoodModel>.from(allFoods),
              );

              return Column(
                children: <Widget>[
                  _buildSearchBox(),
                  _buildCategoryBar(categories),
                  _buildFilterBar(),
                  const Divider(height: 1, color: AppTheme.dividerColor),
                  Expanded(
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? const Center(child: CircularProgressIndicator())
                        : _buildFoodResults(foods),
                  ),
                ],
              );
            },
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: _controller,
        onChanged: (String value) => setState(() => _query = value),
        decoration: InputDecoration(
          hintText: 'Tìm món ăn, nhà hàng...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    setState(() => _query = '');
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildCategoryBar(List<String> categories) {
    return Container(
      color: Colors.white,
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, int i) {
          final String category = categories[i];
          final bool selected = category == _selectedCategory;
          return ChoiceChip(
            selected: selected,
            label: Text(category),
            onSelected: (_) => setState(() => _selectedCategory = category),
          );
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, int i) {
          final bool selected = _filters[i] == _selectedFilter;
          return FilterChip(
            selected: selected,
            label: Text(_filters[i]),
            onSelected: (_) => setState(() => _selectedFilter = _filters[i]),
          );
        },
      ),
    );
  }

  List<FoodModel> _applyFilters(List<FoodModel> input) {
    final String q = _query.trim().toLowerCase();
    List<FoodModel> list = input;

    if (_selectedCategory != 'Tất cả') {
      list = list
          .where((FoodModel food) => food.category.trim() == _selectedCategory)
          .toList();
    }

    if (q.isNotEmpty) {
      list = list.where((FoodModel food) {
        return food.name.toLowerCase().contains(q) ||
            food.category.toLowerCase().contains(q) ||
            food.restaurant.toLowerCase().contains(q) ||
            food.description.toLowerCase().contains(q);
      }).toList();
    }

    switch (_selectedFilter) {
      case 'Danh gia cao':
        list.sort((FoodModel a, FoodModel b) => b.rating.compareTo(a.rating));
        break;
      case 'Gia thap-cao':
        list.sort((FoodModel a, FoodModel b) => a.price.compareTo(b.price));
        break;
      case 'Moi nhat':
        list.sort(
          (FoodModel a, FoodModel b) => b.createdAt.compareTo(a.createdAt),
        );
        break;
      default:
        break;
    }

    return list;
  }

  Widget _buildFoodResults(List<FoodModel> foods) {
    if (foods.isEmpty) {
      return const Center(
        child: Text(
          'Không tìm thấy món phù hợp',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: foods.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, int i) {
        final FoodModel food = foods[i];
        final ProductModel product = ProductModel(
          id: food.id,
          name: food.name,
          description: food.description,
          price: food.price,
          imageUrl: food.imageUrl,
          category: food.category,
          rating: food.rating,
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: ListTile(
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.foodDetail,
                arguments: FoodDetailRouteArgs(foodId: food.id),
              );
            },
            contentPadding: const EdgeInsets.all(10),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: food.imageUrl.isNotEmpty
                    ? Image.network(
                        food.imageUrl,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.low,
                        cacheWidth: 256,
                      )
                    : Container(
                        color: const Color(0xFFF2F2F2),
                        child: const Icon(Icons.fastfood),
                      ),
              ),
            ),
            title: Text(
              food.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              food.available
                  ? '${food.category}  •  ${food.rating.toStringAsFixed(1)}★'
                  : '${food.category}  •  Hết hàng',
              maxLines: 1,
            ),
            trailing: SizedBox(
              width: 98,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '${food.price.toStringAsFixed(0)}d',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Consumer<FavoritesProvider>(
                    builder: (_, FavoritesProvider fav, __) {
                      final bool isFav = fav.isFavorite(food.id);
                      return InkWell(
                        onTap: () => fav.toggleFavorite(product),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_outline,
                          color: isFav ? AppTheme.primaryColor : Colors.grey,
                          size: 20,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      if (!food.available) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Món này hiện đang hết hàng.'),
                          ),
                        );
                        return;
                      }
                      Provider.of<CartProvider>(
                        context,
                        listen: false,
                      ).addItem(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Da them ${food.name} vao gio')),
                      );
                    },
                    child: Icon(
                      Icons.add_shopping_cart,
                      color: food.available
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
