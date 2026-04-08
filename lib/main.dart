import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
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
import 'providers/user_provider.dart';
import 'providers/category_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/address_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/voucher_provider.dart';
import 'utils/notification_service.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await NotificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()..fetchFavorites()),
        ChangeNotifierProvider(create: (_) => AddressProvider()..fetchAddresses()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => VoucherProvider()..fetchVouchers()),
      ],
      child: const MainApp(),
    ),
  );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String? _currentUid;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Lắng nghe trạng thái đăng nhập để start/stop order listener
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (!mounted) return;
        final provider =
            Provider.of<NotificationProvider>(context, listen: false);

        if (user != null && user.uid != _currentUid) {
          _currentUid = user.uid;
          provider.startOrderListener(user.uid);
        } else if (user == null) {
          _currentUid = null;
          provider.stopOrderListener();
        }
      });

      // Lắng nghe voucher mới từ Firestore
      FirebaseFirestore.instance
          .collection('vouchers')
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        final provider =
            Provider.of<NotificationProvider>(context, listen: false);

        for (var change in snap.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data != null) {
              final title = '🎉 Voucher Mới';
              final body = 'Bạn có mã giảm giá mới: ${data['code']}';

              provider.addNotification(
                title: title,
                body: body,
                type: NotifType.voucher,
              );
              NotificationService.showNotification(title: title, body: body);
            }
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Antigravity Store',
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food Delivery App',
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
            builder: (_) => CategoryScreen(
              initialCategory: args?.initialCategory,
              onlyTrending: args?.onlyTrending ?? false,
            ),
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
