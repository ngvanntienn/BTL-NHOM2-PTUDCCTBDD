import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/cart_provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final cart = Provider.of<CartProvider>(context, listen: false);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Danh sách yêu thích'),
      ),
      body: favoritesProvider.favorites.isEmpty
          ? _emptyFavorites()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favoritesProvider.favorites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final p = favoritesProvider.favorites[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(p.imageUrl, width: 80, height: 80, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(p.category, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            const SizedBox(height: 8),
                            Text(currencyFormat.format(p.price * 1000),
                                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.favorite_rounded, color: AppTheme.primaryColor),
                            onPressed: () => favoritesProvider.toggleFavorite(p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_shopping_cart, color: AppTheme.primaryColor, size: 20),
                            onPressed: () {
                              cart.addItem(p);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã thêm ${p.name} vào giỏ hàng')));
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _emptyFavorites() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded, size: 80, color: AppTheme.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 20),
          const Text('Chưa có món ăn yêu thích nào', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }
}
