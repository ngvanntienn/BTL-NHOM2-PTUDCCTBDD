import 'package:flutter/material.dart';
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

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Healthy',  'icon': Icons.eco_outlined,            'color': Color(0xFF4CAF50)},
    {'label': 'Burgers',  'icon': Icons.lunch_dining_outlined,   'color': Color(0xFFFF9800)},
    {'label': 'Pizza',    'icon': Icons.local_pizza_outlined,    'color': Color(0xFFE91E63)},
    {'label': 'Drinks',   'icon': Icons.local_bar_outlined,      'color': Color(0xFF2196F3)},
    {'label': 'Noodles',  'icon': Icons.ramen_dining_outlined,   'color': Color(0xFFD32027)},
    {'label': 'Snacks',   'icon': Icons.cookie_outlined,         'color': Color(0xFF795548)},
    {'label': 'Coffee',   'icon': Icons.coffee_outlined,         'color': Color(0xFF6D4C41)},
    {'label': 'Sushi',    'icon': Icons.set_meal_outlined,       'color': Color(0xFF009688)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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

          // ── Filter Chips ─────────────────────────────────────────
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

          // ── Body ─────────────────────────────────────────────────
          Expanded(
            child: _query.isEmpty ? _buildCategoryGrid() : _buildEmptyResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Explore Categories',
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
            itemCount: _categories.length,
            itemBuilder: (context, i) {
              final cat = _categories[i];
              return Container(
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
                        color: (cat['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text(cat['label'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('"$_query"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text('Không tìm thấy kết quả.\nThử từ khóa khác nhé!',
              textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }
}
