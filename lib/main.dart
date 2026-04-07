import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_routes.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home/user_home.dart';
import 'screens/home/seller_home.dart';
import 'screens/home/admin_home.dart';
import 'screens/user_tabs/chatbot_screen.dart';
import 'screens/user_tabs/favorites_screen.dart';
import 'screens/user_tabs/voucher_screen.dart';
import 'screens/user_tabs/order_history_screen.dart';
import 'screens/user_tabs/edit_profile_screen.dart';
import 'screens/food/category_screen.dart';
import 'screens/food/food_detail_screen.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Antigravity Store',
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.userHome: (_) => const UserHomeScreen(),
        AppRoutes.sellerHome: (_) => const SellerHomeScreen(),
        AppRoutes.adminHome: (_) => const AdminHomeScreen(),
        AppRoutes.chatbot: (_) => const ChatbotScreen(),
        AppRoutes.favorites: (_) => const FavoritesScreen(),
        AppRoutes.voucher: (_) => const VoucherScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.category) {
          final args = settings.arguments as CategoryRouteArgs?;
          return MaterialPageRoute(
            builder: (_) => CategoryScreen(initialCategory: args?.initialCategory),
          );
        }

        if (settings.name == AppRoutes.foodDetail) {
          final args = settings.arguments as FoodDetailRouteArgs?;
          if (args == null) {
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          }
          return MaterialPageRoute(
            builder: (_) => FoodDetailScreen(foodId: args.foodId),
          );
        }

        if (settings.name == AppRoutes.orderHistory) {
          final args = settings.arguments as OrderHistoryRouteArgs?;
          return MaterialPageRoute(
            builder: (_) => OrderHistoryScreen(
              initialFilter: args?.initialFilter ?? 'all',
            ),
          );
        }

        if (settings.name == AppRoutes.editProfile) {
          final args = settings.arguments as EditProfileRouteArgs?;
          if (args == null) {
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          }
          return MaterialPageRoute(
            builder: (_) => EditProfileScreen(userData: args.userData),
          );
        }

        return null;
      },
    );
  }
}
