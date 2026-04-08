import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const String _storageKey = 'search_history';
  static const int _maxHistoryItems = 20;

  // Add search to history
  Future<void> addSearchQuery(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = await getSearchHistory();

      // Remove if already exists (to move to top)
      history.removeWhere((item) => item.toLowerCase() == query.toLowerCase());

      // Add to beginning
      history.insert(0, query.trim());

      // Keep only max items
      if (history.length > _maxHistoryItems) {
        history = history.sublist(0, _maxHistoryItems);
      }

      await prefs.setStringList(_storageKey, history);
    } catch (e) {
      print('Lỗi lưu lịch sử tìm kiếm: $e');
    }
  }

  // Get all search history
  Future<List<String>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_storageKey) ?? [];
    } catch (e) {
      print('Lỗi đọc lịch sử tìm kiếm: $e');
      return [];
    }
  }

  // Clear single search item
  Future<void> removeSearchQuery(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = await getSearchHistory();
      history.removeWhere((item) => item == query);
      await prefs.setStringList(_storageKey, history);
    } catch (e) {
      print('Lỗi xóa lịch sử tìm kiếm: $e');
    }
  }

  // Clear all history
  Future<void> clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      print('Lỗi xóa toàn bộ lịch sử tìm kiếm: $e');
    }
  }

  // Get trending searches (most searched)
  Future<List<String>> getTrendingSearches({int limit = 10}) async {
    List<String> history = await getSearchHistory();

    // Count occurrences
    Map<String, int> searchCounts = {};
    for (String search in history) {
      searchCounts[search] = (searchCounts[search] ?? 0) + 1;
    }

    // Sort by count and return top
    final sorted = searchCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) => e.key).toList();
  }
}
