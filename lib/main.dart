import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_routes.dart';
import 'firebase_options.dart';
import 'providers/address_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/category_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/user_provider.dart';
import 'providers/voucher_provider.dart';
import 'screens/food/category_screen.dart';
import 'screens/admin/admin_security_screen.dart';
import 'screens/food/food_detail_screen.dart';
import 'screens/home/seller_home.dart';
import 'screens/home/user_home.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/user_tabs/chatbot_screen.dart';
import 'screens/user_tabs/edit_profile_screen.dart';
import 'screens/user_tabs/favorites_screen.dart';
import 'screens/user_tabs/order_history_screen.dart';
import 'screens/user_tabs/voucher_screen.dart';
import 'theme/app_theme.dart';
import 'utils/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.initialize();

  runApp(
    MultiProvider(
      providers: <ChangeNotifierProvider<dynamic>>[
        ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
        ChangeNotifierProvider<CategoryProvider>(
          create: (_) => CategoryProvider(),
        ),
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
        ChangeNotifierProvider<FavoritesProvider>(
          create: (_) => FavoritesProvider()..fetchFavorites(),
        ),
        ChangeNotifierProvider<AddressProvider>(
          create: (_) => AddressProvider()..fetchAddresses(),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
        ChangeNotifierProvider<VoucherProvider>(
          create: (_) => VoucherProvider()..fetchVouchers(),
        ),
      ],
      child: const MainApp(),
    ),
  );
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
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (!mounted) {
          return;
        }

        final NotificationProvider provider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
        final FavoritesProvider favoritesProvider =
            Provider.of<FavoritesProvider>(context, listen: false);

        if (user != null && user.uid != _currentUid) {
          _currentUid = user.uid;
          provider.startOrderListener(user.uid);
          favoritesProvider.fetchFavorites();
        } else if (user == null) {
          _currentUid = null;
          provider.stopOrderListener();
          favoritesProvider.clearFavorites(notify: true);
        }
      });

      FirebaseFirestore.instance.collection('vouchers').snapshots().listen((
        QuerySnapshot<Map<String, dynamic>> snap,
      ) {
        if (!mounted) {
          return;
        }

        final NotificationProvider provider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );

        for (final DocumentChange<Map<String, dynamic>> change
            in snap.docChanges) {
          if (change.type != DocumentChangeType.added) {
            continue;
          }

          final Map<String, dynamic>? data = change.doc.data();
          if (data == null) {
            continue;
          }

          final String code = (data['code'] ?? '').toString();
          if (code.isEmpty) {
            continue;
          }

          provider.addNotification(
            title: 'Voucher moi',
            body: 'Bạn có mã giảm giá mới: $code',
            type: NotifType.voucher,
          );
          NotificationService.showNotification(
            title: 'Voucher moi',
            body: 'Bạn có mã giảm giá mới: $code',
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food Delivery App',
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: <String, WidgetBuilder>{
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.userHome: (_) => const UserHomeScreen(),
        AppRoutes.sellerHome: (_) => const SellerHomeScreen(),
        AppRoutes.adminHome: (_) => const AdminSecurityScreen(),
        AppRoutes.chatbot: (_) => const ChatbotScreen(),
        AppRoutes.favorites: (_) => const FavoritesScreen(),
        AppRoutes.voucher: (_) => const VoucherScreen(),
      },
      onGenerateRoute: (RouteSettings settings) {
        if (settings.name == AppRoutes.category) {
          final CategoryRouteArgs? args =
              settings.arguments as CategoryRouteArgs?;
          return MaterialPageRoute<void>(
            builder: (_) => CategoryScreen(
              initialCategory: args?.initialCategory,
              onlyTrending: args?.onlyTrending ?? false,
            ),
          );
        }

        if (settings.name == AppRoutes.foodDetail) {
          final FoodDetailRouteArgs? args =
              settings.arguments as FoodDetailRouteArgs?;
          if (args == null) {
            return MaterialPageRoute<void>(
              builder: (_) => const SplashScreen(),
            );
          }
          return MaterialPageRoute<void>(
            builder: (_) => FoodDetailScreen(foodId: args.foodId),
          );
        }

        if (settings.name == AppRoutes.orderHistory) {
          final OrderHistoryRouteArgs? args =
              settings.arguments as OrderHistoryRouteArgs?;
          return MaterialPageRoute<void>(
            builder: (_) =>
                OrderHistoryScreen(initialFilter: args?.initialFilter ?? 'all'),
          );
        }

        if (settings.name == AppRoutes.editProfile) {
          final EditProfileRouteArgs? args =
              settings.arguments as EditProfileRouteArgs?;
          if (args == null) {
            return MaterialPageRoute<void>(
              builder: (_) => const SplashScreen(),
            );
          }
          return MaterialPageRoute<void>(
            builder: (_) => EditProfileScreen(userData: args.userData),
          );
        }

        return null;
      },
    );
  }
}
