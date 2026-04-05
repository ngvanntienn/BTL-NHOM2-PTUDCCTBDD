import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food Delivery App',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
