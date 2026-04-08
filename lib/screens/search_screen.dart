import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/food_service.dart';
import '../../services/search_history_service.dart';
import '../../models/food_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _foodService = FoodService();
  final _historyService = SearchHistoryService();

  String _selectedCategory = 'Tất cả';
  String _query = '';
  double _minPrice = 0;
  double _maxPrice = 1000000;
  double _minRating = 0;
  bool _showAdvancedFilters = false;
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    final history = await _historyService.getSearchHistory();
    setState(() => _searchHistory = history);
  }

  void _performSearch() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      _historyService.addSearchQuery(query);
      _loadSearchHistory();
      setState(() {});
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
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
          onSubmitted: (_) => _performSearch(),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm món ăn...',
            border: InputBorder.none,
            hintStyle: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: AppTheme.textPrimary),
              onPressed: () => setState(() => _controller.clear()),
            ),
          IconButton(
            icon: const Icon(Icons.tune, color: AppTheme.textPrimary),
            onPressed: () =>
                setState(() => _showAdvancedFilters = !_showAdvancedFilters),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Category filter pills
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: FutureBuilder<List<String>>(
                future: _foodService.getCategories(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();

                  final categories = ['Tất cả', ...snapshot.data!];
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories
                          .map(
                            (cat) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(
                                  cat,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                selected: _selectedCategory == cat,
                                onSelected: (_) {
                                  setState(() => _selectedCategory = cat);
                                },
                                backgroundColor: Colors.grey[200],
                                selectedColor: AppTheme.primaryColor,
                                labelStyle: TextStyle(
                                  color: _selectedCategory == cat
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
              ),
            ),

            // Advanced filters section
            if (_showAdvancedFilters) _buildAdvancedFilters(),

            // Search suggestions or history
            if (_query.isEmpty && _searchHistory.isNotEmpty)
              _buildSearchHistory()
            else if (_query.isNotEmpty)
              _buildSearchResults(_query)
            else if (_searchHistory.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.search, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text(
                        'Tìm kiếm món ăn yêu thích',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bộ lọc nâng cao',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Price range
          const Text(
            'Khoảng giá:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _minPrice.toInt().toString(),
                  decoration: InputDecoration(
                    hintText: 'Min',
                    contentPadding: const EdgeInsets.all(8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                  ),
                  onChanged: (val) =>
                      setState(() => _minPrice = double.tryParse(val) ?? 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: _maxPrice.toInt().toString(),
                  decoration: InputDecoration(
                    hintText: 'Max',
                    contentPadding: const EdgeInsets.all(8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                  ),
                  onChanged: (val) => setState(
                    () => _maxPrice = double.tryParse(val) ?? 1000000,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rating filter
          const Text(
            'Đánh giá tối thiểu:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ...List.generate(
                5,
                (i) => Tooltip(
                  message: '${i + 1} sao',
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _minRating = (i + 1).toDouble()),
                    child: Icon(
                      Icons.star,
                      size: 24,
                      color: _minRating > i
                          ? AppTheme.primaryColor
                          : Colors.grey[300],
                    ),
                  ),
                ),
              ),
              Text(
                _minRating > 0 ? '${_minRating.toInt()} sao+' : 'Tất cả',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lịch sử tìm kiếm',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              GestureDetector(
                onTap: () {
                  _historyService.clearSearchHistory();
                  _loadSearchHistory();
                },
                child: const Text(
                  'Xóa tất cả',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _searchHistory.length,
          itemBuilder: (context, index) {
            final query = _searchHistory[index];
            return ListTile(
              leading: const Icon(
                Icons.history,
                size: 18,
                color: AppTheme.textSecondary,
              ),
              title: Text(query, style: const TextStyle(fontSize: 13)),
              trailing: GestureDetector(
                onTap: () {
                  _historyService.removeSearchQuery(query);
                  _loadSearchHistory();
                },
                child: const Icon(Icons.close, size: 18, color: Colors.grey),
              ),
              onTap: () {
                _controller.text = query;
                setState(() => _query = query);
                _performSearch();
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchResults(String query) {
    return FutureBuilder<List<FoodModel>>(
      future: _foodService.advancedSearch(
        query: query,
        category: _selectedCategory,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating > 0 ? _minRating : null,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }

        final foods = snapshot.data ?? [];

        if (foods.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'Không tìm thấy kết quả',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Thử tìm kiếm với từ khóa khác',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: foods.length,
          itemBuilder: (context, index) => _buildFoodCard(foods[index]),
        );
      },
    );
  }

  Widget _buildFoodCard(FoodModel food) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${food.name} được chọn'))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Container(
                height: 110,
                color: const Color(0xFFF5F5F5),
                child: food.imageUrl.isNotEmpty
                    ? Image.network(
                        food.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_outlined,
                          color: Colors.grey,
                        ),
                      )
                    : const Icon(Icons.image_outlined, color: Colors.grey),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${food.rating}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${food.reviewCount})',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${food.price.toStringAsFixed(0)}đ',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
