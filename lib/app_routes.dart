class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String userHome = '/user-home';
  static const String sellerHome = '/seller-home';
  static const String adminHome = '/admin-home';
  static const String chatbot = '/chatbot';
  static const String category = '/category';
  static const String foodDetail = '/food-detail';
  static const String favorites = '/favorites';
  static const String voucher = '/voucher';
  static const String orderHistory = '/order-history';
  static const String editProfile = '/edit-profile';
}

class CategoryRouteArgs {
  const CategoryRouteArgs({this.initialCategory, this.onlyTrending = false});

  final String? initialCategory;
  final bool onlyTrending;
}

class FoodDetailRouteArgs {
  const FoodDetailRouteArgs({required this.foodId});

  final String foodId;
}

class OrderHistoryRouteArgs {
  const OrderHistoryRouteArgs({this.initialFilter = 'all'});

  final String initialFilter;
}

class EditProfileRouteArgs {
  const EditProfileRouteArgs({required this.userData});

  final Map<String, dynamic> userData;
}
