import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../models/order_model.dart';
import '../services/audio_service.dart';
import 'new_order_screen.dart';
import 'orders_screen.dart';
import 'order_history_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

/// Main home screen with bottom navigation bar.
/// Four tabs: Orders, New Order, History, Profile
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 2; // Default to New Order (Add Request) tab in the middle
  List<String> _previousOrderIds = [];
  bool _isFirstLoad = true;

  void setTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final _screens = [
    const OrdersScreen(),
    const OrderHistoryScreen(),
    const NewOrderScreen(),
    const ProfileScreen(),
    const SettingsScreen(isTab: true),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<app_auth.AuthProvider>();
    final firestoreService = FirestoreService();
    final userId = authProvider.user?.uid ?? '';

    final titles = [
      context.tr('tab_orders'),
      context.tr('tab_history'),
      context.tr('tab_new_order'),
      context.tr('tab_profile'),
      context.tr('tab_settings'),
    ];

    return StreamBuilder<List<Order>>(
      stream: userId.isNotEmpty
          ? firestoreService.streamOrdersForReceiver(userId)
          : const Stream.empty(),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];

        final showBanner = (authProvider.appUser?.role == 'super_admin' || authProvider.user?.email == 'hhcgjvhcnk@gmail.com') &&
            (authProvider.appUser?.shopId == null || authProvider.appUser!.shopId!.isEmpty);

        // Check for new incoming orders and play chime sound
        final currentOrderIds = orders.map((o) => o.id).toList();
        if (_isFirstLoad) {
          _isFirstLoad = false;
          _previousOrderIds = currentOrderIds;
        } else {
          final hasNewOrder = currentOrderIds.any((id) => !_previousOrderIds.contains(id));
          if (hasNewOrder) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AudioService.playReceive();
            });
          }
          _previousOrderIds = currentOrderIds;
        }

        return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onDoubleTap: () async {
            final currentUid = userId;
            if (currentUid.isEmpty) return;

            final dummyOrder = Order(
              id: 'dummy_${DateTime.now().millisecondsSinceEpoch}',
              senderId: 'system_test',
              senderName: 'فريق الدعم (تحديث تلقائي)',
              receiverId: currentUid,
              receiverName: authProvider.appUser?.displayName ?? 'كاشير',
              status: 'pending',
              createdAt: DateTime.now(),
              customerName: 'زبون تجريبي (صوت)',
              fabrics: [
                FabricEntry(
                  fabricType: 'حرير ممتاز (تجربة)',
                  unit: 'meter',
                  price: 1500.0,
                  lengths: {'50': 1, '30': 1},
                  sequence: [50.0, 30.0],
                ),
              ],
            );

            try {
              await firestoreService.createOrder(dummyOrder);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم إرسال طلب تجريبي لمحاكاة الاستلام...'),
                  duration: Duration(seconds: 2),
                ),
              );
            } catch (e) {
              print('Dummy order error: $e');
            }
          },
          child: Row(
            children: [
              Hero(
                tag: 'logo',
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.borderSubtle,
                      width: 1.5,
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
                           size: 20,
                           color: AppTheme.accentAmber,
                         ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titles[_currentIndex],
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // User info chip
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppTheme.accentAmber,
                  backgroundImage: authProvider.appUser?.photoBase64 != null &&
                          authProvider.appUser!.photoBase64!.isNotEmpty
                      ? MemoryImage(base64Decode(authProvider.appUser!.photoBase64!))
                      : null,
                  child: authProvider.appUser?.photoBase64 == null ||
                          authProvider.appUser!.photoBase64!.isEmpty
                      ? Text(
                          authProvider.displayName.isNotEmpty
                              ? authProvider.displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.surfaceDark,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 80),
                  child: Text(
                    authProvider.displayName,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Swap shop button for super admin
          if (authProvider.appUser?.role == 'super_admin' || authProvider.user?.email == 'hhcgjvhcnk@gmail.com')
            IconButton(
              icon: Icon(
                Icons.swap_horiz_rounded,
                color: AppTheme.accentAmber,
                size: 24,
              ),
              onPressed: () => _showShopSwitcherDialog(context, authProvider),
              tooltip: 'التنقل بين المحلات',
            ),

          // Sign out
          IconButton(
            icon: Icon(
              Icons.logout_rounded,
              color: AppTheme.textMuted,
              size: 22,
            ),
            onPressed: () => _showSignOutDialog(context, authProvider),
            tooltip: context.tr('sign_out'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          if (showBanner)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                border: Border(bottom: BorderSide(color: Colors.amber.withValues(alpha: 0.3))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'أنت غير مرتبط بأي محل حالياً. اضغط على أيقونة التبديل ⇆ في الأعلى للارتباط بمحل والبدء في إدارة ومتابعة الطلبات كعضو فيه.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: _screens[_currentIndex],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.borderSubtle, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (i) => setState(() => _currentIndex = i),
          items: [
            BottomNavigationBarItem(
              icon: _buildOrdersIcon(false, orders),
              activeIcon: _buildOrdersIcon(true, orders),
              label: context.tr('tab_orders'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history_rounded),
              activeIcon: const Icon(Icons.history_rounded),
              label: context.tr('tab_history'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.add_circle_outline_rounded),
              activeIcon: const Icon(Icons.add_circle_rounded),
              label: context.tr('tab_new_order'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded),
              activeIcon: const Icon(Icons.person_rounded),
              label: context.tr('tab_profile'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings_rounded),
              label: context.tr('tab_settings'),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildOrdersIcon(bool isActive, List<Order> orders) {
    final hasDraft = orders.any((o) => o.isDraft);
    final hasNormal = orders.any((o) => !o.isDraft);

    Color? dotColor;
    if (hasNormal) {
      dotColor = AppTheme.error; // Red dot
    } else if (hasDraft) {
      dotColor = Colors.orange; // Orange dot
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          Icons.inbox_rounded,
          color: isActive ? AppTheme.accentAmber : AppTheme.textMuted,
        ),
        if (dotColor != null)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.surfaceDark, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showSignOutDialog(
      BuildContext context, app_auth.AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('sign_out')),
        content: Text(context.tr('sign_out_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              authProvider.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: Text(context.tr('logout')),
          ),
        ],
      ),
    );
  }

  void _showShopSwitcherDialog(BuildContext context, app_auth.AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('التنقل بين المحلات'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreService().streamAllShops(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final shops = snapshot.data ?? [];
              final currentShopId = authProvider.appUser?.shopId;

              return ListView(
                shrinkWrap: true,
                children: [
                  // Option to disconnect/unlink (no shop)
                  ListTile(
                    title: const Text(
                      'إلغاء الربط (بدون محل)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    leading: Icon(
                      Icons.link_off_rounded,
                      color: currentShopId == null ? AppTheme.accentAmber : AppTheme.textMuted,
                    ),
                    trailing: currentShopId == null
                        ? Icon(Icons.check_circle_rounded, color: AppTheme.accentAmber)
                        : null,
                    onTap: () async {
                      Navigator.of(dialogCtx).pop();
                      final success = await authProvider.switchShop(null);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم إلغاء ربط الحساب بالمحل بنجاح.')),
                        );
                      }
                    },
                  ),
                  const Divider(),
                  ...shops.map((shop) {
                    final shopId = shop['id'] as String? ?? '';
                    final shopName = shop['name'] as String? ?? 'محل بدون اسم';
                    final isCurrent = currentShopId == shopId;

                    return ListTile(
                      title: Text(shopName),
                      leading: Icon(
                        Icons.store_rounded,
                        color: isCurrent ? AppTheme.accentAmber : AppTheme.textMuted,
                      ),
                      trailing: isCurrent
                          ? Icon(Icons.check_circle_rounded, color: AppTheme.accentAmber)
                          : null,
                      onTap: () async {
                        Navigator.of(dialogCtx).pop();
                        final success = await authProvider.switchShop(shopId);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تم الانتقال إلى محل "$shopName" بنجاح.')),
                          );
                        }
                      },
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
