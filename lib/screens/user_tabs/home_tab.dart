import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_routes.dart';
import '../../models/food_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/notification_provider.dart';
import 'notification_screen.dart';

class HomeTab extends StatelessWidget {
  final VoidCallback? onSeeAll;
  final Function(String)? onCategorySelected;

  const HomeTab({super.key, this.onSeeAll, this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hôm nay bạn muốn ăn gì? 👋',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tìm kiếm món ngon xung quanh bạn',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 16),

                    // Search Bar
                    GestureDetector(
                      onTap: onSeeAll,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.dividerColor),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                            SizedBox(width: 10),
                            Text('Tìm món ăn, quán ăn...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Promo Banner
                    Container(
                      height: 145,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD32027), Color(0xFF8B0000)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'ĐẶT NGAY HÔM NAY',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Giảm tới 50%\ncho Bún & Phở',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.ramen_dining, color: Colors.white54, size: 80),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    _buildAiBanner(),
                    const SizedBox(height: 28),

                    _sectionHeader('Món đang thịnh hành', 'Xem tất cả'),
                    const SizedBox(height: 16),

                    // Load từ Firestore
                    _buildTrendingFromFirestore(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.fastfood_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Giao đến', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: AppTheme.primaryColor, size: 14),
                      SizedBox(width: 2),
                      Text('Chọn địa chỉ', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                      Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor, size: 18),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Consumer<NotificationProvider>(
            builder: (context, provider, _) => Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
                  icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.textPrimary, size: 26),
                ),
                if (provider.unreadCount > 0)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context,
    String title,
    String action, {
    VoidCallback? onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textPrimary)),
        InkWell(
          onTap: onTap,
          child: Text(action, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildCategoryRow(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('foods').snapshots(),
      builder: (context, snapshot) {
        final Set<String> set = <String>{};
        for (final doc in snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
          final String category = (doc.data()['category'] ?? '').toString().trim();
          if (category.isNotEmpty) {
            set.add(category);
          }
        }

        final List<String> categories = set.isEmpty
            ? <String>['Cơm', 'Bún', 'Trà sữa', 'Pizza', 'Coffee', 'Snack', 'Bánh mì', 'Khác']
            : set.toList()..sort();

        return SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: categories.length > 8 ? 8 : categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final String label = categories[i];
              return GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.category,
                  arguments: CategoryRouteArgs(initialCategory: label),
                ),
                child: SizedBox(
                  width: 64,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.09),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.fastfood_outlined,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: AppTheme.textPrimary)),
        GestureDetector(
          onTap: onSeeAll,
          child: Text(action,
              style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildCategoryRow() {
    final cats = [
      {'icon': Icons.rice_bowl_outlined,     'label': 'Cơm'},
      {'icon': Icons.ramen_dining_outlined,   'label': 'Bún & Phở'},
      {'icon': Icons.local_drink_outlined,    'label': 'Trà sữa'},
      {'icon': Icons.fastfood_outlined,       'label': 'Snacks'},
      {'icon': Icons.local_pizza_outlined,    'label': 'Pizza'},
      {'icon': Icons.bakery_dining_outlined,  'label': 'Bánh mì'},
      {'icon': Icons.coffee_outlined,         'label': 'Coffee'},
      {'icon': Icons.more_horiz,              'label': 'Thêm'},
    ];
    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final cat = cats[i];
          final isMore = cat['label'] == 'Thêm';
          final label = cat['label'] as String;
          return GestureDetector(
            onTap: () {
              if (onCategorySelected != null) {
                onCategorySelected!(label);
              }
            },
            child: SizedBox(
              width: 54,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isMore
                          ? const Color(0xFFF0F0F0)
                          : AppTheme.primaryColor.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      color: isMore ? AppTheme.textSecondary : AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    cat['label'] as String,
                    style: const TextStyle(fontSize: 10, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAiBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.06), blurRadius: 10)],
      ),
      child: const Row(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.smart_toy_outlined, color: AppTheme.primaryColor, size: 28),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gợi ý từ AI Chef', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
                SizedBox(height: 3),
                Text('Bấm Robot ở dưới để AI đề xuất món ngon!', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, AppRoutes.chatbot),
              child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingRow(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('foods').limit(20).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 195,
            child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
          );
        }

        final List<FoodModel> foods = snapshot.data?.docs.map(FoodModel.fromDoc).toList() ?? <FoodModel>[];

        final List<FoodModel> trendingFoods = foods.where((food) => food.isTrending).toList();
        final List<FoodModel> source = trendingFoods.isEmpty ? foods : trendingFoods;

        if (source.isEmpty) {
          return Container(
            height: 120,
            alignment: Alignment.center,
          Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.arrow_forward, color: AppTheme.primaryColor, size: 16),
          ),
        ],
      ),
    );
  }

  // ── Load sản phẩm từ Firestore ──────────────────────────────────────
  Widget _buildTrendingFromFirestore(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('foods').limit(10).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
          );
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: Text('Chưa có sản phẩm nào', style: TextStyle(color: AppTheme.textSecondary)),
            ),
          );
        }
        final products = docs.map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return ProductModel(
            id: doc.id,
            name: d['name'] ?? '',
            description: d['description'] ?? '',
            price: (d['price'] as num?)?.toDouble() ?? 0.0,
            imageUrl: d['imageUrl'] ?? '',
            category: d['category'] ?? '',
          );
        }).toList();
        return _buildTrendingRow(context, products);
      },
    );
  }

  Widget _buildTrendingRow(BuildContext context, List<ProductModel> products) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final cart = Provider.of<CartProvider>(context, listen: false);

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final p = products[i];
          return Container(
            width: 160,
>>>>>>> main
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: const Text(
              'Chưa có món thịnh hành từ Firestore',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        return SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: source.length > 8 ? 8 : source.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) {
              final FoodModel food = source[i];
              return InkWell(
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.foodDetail,
                  arguments: FoodDetailRouteArgs(foodId: food.id),
                ),
                child: Container(
                  width: 152,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.dividerColor),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: SizedBox(
                          height: 118,
                          width: double.infinity,
                          child: food.imageUrl.isNotEmpty
                              ? Image.network(
                                  food.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _fallbackImage(),
                                )
                              : _fallbackImage(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              food.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${food.price.toStringAsFixed(0)}đ',
                                  style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                                    const SizedBox(width: 2),
                                    Text(
                                      food.rating == 0 ? 'Mới' : food.rating.toStringAsFixed(1),
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                    ),
                                  ],
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: const Center(child: Icon(Icons.image_outlined, color: Colors.grey, size: 36)),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    children: [
                      Container(
                        height: 120,
                        width: double.infinity,
                        color: const Color(0xFFF5F5F5),
                        child: p.imageUrl.isNotEmpty
                            ? Image.network(p.imageUrl, fit: BoxFit.cover)
                            : const Center(child: Icon(Icons.image_outlined, color: Colors.grey, size: 36)),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Consumer<FavoritesProvider>(
                          builder: (context, favorites, _) {
                            final isFav = favorites.isFavorite(p.id);
                            return GestureDetector(
                              onTap: () => favorites.toggleFavorite(p),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: Icon(
                                  isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                  color: isFav ? AppTheme.primaryColor : Colors.grey,
                                  size: 18,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                      const SizedBox(height: 4),
                      Text(p.category, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(currencyFormat.format(p.price * 1000),
                              style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                          GestureDetector(
                            onTap: () {
                              cart.addItem(p);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Đã thêm ${p.name} vào giỏ hàng'), duration: const Duration(seconds: 1)),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.add, color: Colors.white, size: 16),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
