import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter_web_plugins/url_strategy.dart';

import 'providers/auth_provider.dart' as app_auth;
import 'providers/order_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/subscription_expired_screen.dart';
import 'theme/app_theme.dart';
import 'services/firestore_service.dart';
import 'services/fcm_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with hardcoded options (no google-services.json needed)
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyCtEPgAIoEY6rZpzYBAurutr-kCobJaaBI',
      appId: kIsWeb 
          ? '1:368377187521:web:279c079cdad3f9f0d5d840' 
          : '1:368377187521:android:b04542a9b767eaaed5d840',
      messagingSenderId: '368377187521',
      projectId: 'fantex',
      storageBucket: 'fantex.firebasestorage.app',
      authDomain: 'fantex.firebaseapp.com',
    ),
  );

  // Initialize FCM Service
  try {
    final fcm = FcmService();
    FcmService.navigatorKey = appNavigatorKey;
    await fcm.init();
  } catch (e) {
    debugPrint("Failed to initialize FCM: $e");
  }

  // Clear all global saved lengths (one-time clean up request by user)
  try {
    await FirestoreService().clearAllGlobalSavedLengths();
  } catch (e) {
    debugPrint("Failed to clear global saved lengths: $e");
  }

  // Lock orientation to portrait for store kiosk use
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1A1D27),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const FantexApp());
}

class FantexApp extends StatelessWidget {
  const FantexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'tussi',
            navigatorKey: appNavigatorKey,
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

/// Gate widget that routes to Login or Home based on auth state.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Timer? _timer;
  DateTime _now = DateTime.now();
  String? _lastShopId;
  Stream<Map<String, dynamic>?>? _shopStream;

  @override
  void initState() {
    super.initState();
    // Tick every second to re-evaluate subscription expiry in real time
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<app_auth.AuthProvider>();

    // Show loading while checking auth state
    if (authProvider.isInitializing) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: AppTheme.surfaceGradient),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.surfaceCard,
                    border: Border.all(
                      color: AppTheme.borderSubtle,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Transform.scale(
                      scale: 1.45,
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.store_rounded,
                          size: 48,
                          color: AppTheme.accentAmber,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppTheme.accentAmber,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Route based on auth state
    if (authProvider.isAuthenticated) {
      final user = authProvider.appUser;
      final firebaseUser = authProvider.user;

      final isSuperAdmin = (user != null && user.role == 'super_admin') ||
          (firebaseUser != null && firebaseUser.email == 'hhcgjvhcnk@gmail.com');

      if (user == null) {
        if (isSuperAdmin && firebaseUser != null) {
          // Recreate missing super admin document
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await FirestoreService().recreateSuperAdmin(firebaseUser.uid, firebaseUser.email ?? '');
            // Reload user details in AuthProvider
            await authProvider.reloadUser();
          });
        } else {
          // User document was deleted from Firestore. Force sign out.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            authProvider.signOut();
          });
        }
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(gradient: AppTheme.surfaceGradient),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      }

      // Super admin bypass — never blocked
      if (user.role == 'super_admin' || user.email == 'hhcgjvhcnk@gmail.com') {
        return const HomeScreen();
      }

      final shopId = user.shopId ?? '';
      if (_lastShopId != shopId || _shopStream == null) {
        _lastShopId = shopId;
        _shopStream = FirestoreService().streamShopDetails(shopId);
      }

      // Stream the shop details to check subscription
      return StreamBuilder<Map<String, dynamic>?>(
        stream: _shopStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Container(
                decoration: BoxDecoration(gradient: AppTheme.surfaceGradient),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          final shopData = snapshot.data;
          if (shopData == null) {
            // Shop was deleted or does not exist. Show block screen.
            return const SubscriptionExpiredScreen(
              shopName: 'محل محذوف أو غير موجود',
              expiresAt: null,
              inviteCode: '',
            );
          }

          final bool isActive = shopData['isActive'] as bool? ?? true;
          final Timestamp? expiryTimestamp =
              shopData['subscriptionExpiresAt'] as Timestamp?;
          final String shopName =
              shopData['name'] as String? ?? 'محل غير معروف';
          final String inviteCode =
              shopData['inviteCode'] as String? ?? '';

          // Use _now (updated every second by the Timer) for real-time expiry check
          bool isExpired = false;
          if (expiryTimestamp != null) {
            final expiryDate = expiryTimestamp.toDate();
            isExpired = expiryDate.isBefore(_now);
          }

          if (!isActive || isExpired) {
            return SubscriptionExpiredScreen(
              shopName: shopName,
              expiresAt: expiryTimestamp?.toDate(),
              inviteCode: inviteCode,
            );
          }

          return const HomeScreen();
        },
      );
    } else {
      return const LoginScreen();
    }
  }
}
