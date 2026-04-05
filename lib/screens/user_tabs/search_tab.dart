import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _controller = TextEditingController();
  String _selectedCategory = '';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Khám phá & Tìm kiếm'),
      ),
      body: Column(
        children: [
          // ── Search Bar ───────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _controller,
              onChanged: (v) => setState(() {
                _query = v;
                if (v.isNotEmpty) _selectedCategory = '';
              }),
              decoration: InputDecoration(
                hintText: 'Tìm món ăn ngay...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: _query.isNotEmpty || _selectedCategory.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _controller.clear();
                          _query = '';
                          _selectedCategory = '';
                        }),
                      )
                    : const Icon(Icons.mic_none, color: AppTheme.primaryColor),
              ),
            ),
          ),

          // ── Category Chips ────────────────────────────────────────
          Container(
            color: Colors.white,
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildCategoryChip('Cơm'),
                const SizedBox(width: 8),
                _buildCategoryChip('Bún & Phở'),
                const SizedBox(width: 8),
                _buildCategoryChip('Trà sữa'),
                const SizedBox(width: 8),
                _buildCategoryChip('Pizza'),
                const SizedBox(width: 8),
                _buildCategoryChip('Bánh mì'),
                const SizedBox(width: 8),
                _buildCategoryChip('Snacks'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.dividerColor),

          // ── Product Grid (Firestore) ──────────────────────────────
          Expanded(
            child: _selectedCategory.isEmpty && _query.isEmpty
                ? _buildEmptyPrompt()
                : _buildFirestoreGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    final sel = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedCategory = sel ? '' : label;
        _query = '';
        _controller.clear();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: sel ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? AppTheme.primaryColor : AppTheme.dividerColor),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                color: sel ? Colors.white : AppTheme.textPrimary,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              )),
        ),
      ),
    );
  }

  Widget _buildEmptyPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fastfood_outlined, size: 72, color: AppTheme.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('Chọn một loại đồ ăn ở trên\nđể khám phá món ngon!',
              textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildFirestoreGrid() {
    Query query = FirebaseFirestore.instance.collection('foods');

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }

        var docs = snap.data?.docs ?? [];

        // Lọc theo category
        if (_selectedCategory.isNotEmpty) {
          docs = docs.where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return (d['category'] ?? '') == _selectedCategory;
          }).toList();
        }

        // Lọc theo search query
        if (_query.isNotEmpty) {
          docs = docs.where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return (d['name'] ?? '').toString().toLowerCase().contains(_query.toLowerCase());
          }).toList();
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

        return _buildProductGrid(products);
      },
    );
  }

  Widget _buildProductGrid(List<ProductModel> products) {
    if (products.isEmpty) {
      return const Center(child: Text('Không tìm thấy món bạn yêu cầu.'));
    }

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final cart = Provider.of<CartProvider>(context, listen: false);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, i) {
        final p = products[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: const Color(0xFFF5F5F5),
                        child: p.imageUrl.isNotEmpty
                            ? Image.network(p.imageUrl, fit: BoxFit.cover)
                            : const Center(child: Icon(Icons.image_outlined, color: Colors.grey, size: 36)),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Consumer<FavoritesProvider>(
                          builder: (context, favorites, _) {
                            final isFav = favorites.isFavorite(p.id);
                            return GestureDetector(
                              onTap: () => favorites.toggleFavorite(p),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: Icon(
                                  isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                  color: isFav ? AppTheme.primaryColor : Colors.grey,
                                  size: 20,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(currencyFormat.format(p.price * 1000),
                            style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                        GestureDetector(
                          onTap: () {
                            cart.addItem(p);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Đã thêm ${p.name}'), duration: const Duration(seconds: 1)),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.add, color: Colors.white, size: 16),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
