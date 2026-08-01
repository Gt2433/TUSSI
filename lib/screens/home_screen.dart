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
import '../providers/order_provider.dart';
import '../widgets/order_card.dart';
import '../widgets/ai_assistant_dialog.dart';

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
    final orderProvider = context.watch<OrderProvider>();
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: 'logo',
                child: Container(
                  width: 32,
                  height: 32,
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
                           size: 18,
                           color: AppTheme.accentAmber,
                         ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  titles[_currentIndex],
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        titleSpacing: 8,
        actions: [
          // User info chip
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 10,
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
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.surfaceDark,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 60),
                  child: Text(
                    authProvider.displayName,
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Offline mode toggle and sync status indicator
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                icon: Icon(
                  orderProvider.isOffline
                      ? Icons.wifi_off_rounded
                      : Icons.wifi_rounded,
                  color: orderProvider.isOffline
                      ? Colors.redAccent
                      : AppTheme.accentAmber,
                  size: 20,
                ),
                onPressed: () => _showOfflineDialog(context, orderProvider),
                tooltip: orderProvider.isOffline ? 'الوضع دون اتصال' : 'متصل بالإنترنت',
              ),
              if (!orderProvider.isOffline && orderProvider.offlineOrders.isNotEmpty)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),

          // Swap shop button for super admin
          if (authProvider.appUser?.role == 'super_admin' || authProvider.user?.email == 'hhcgjvhcnk@gmail.com')
            IconButton(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              icon: Icon(
                Icons.swap_horiz_rounded,
                color: AppTheme.accentAmber,
                size: 20,
              ),
              onPressed: () => _showShopSwitcherDialog(context, authProvider),
              tooltip: 'التنقل بين المحلات',
            ),
          const SizedBox(width: 4),



          // Sign out
          IconButton(
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.logout_rounded,
              color: AppTheme.textMuted,
              size: 20,
            ),
            onPressed: () => _showSignOutDialog(context, authProvider),
            tooltip: context.tr('sign_out'),
          ),
          const SizedBox(width: 6),
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

  void _showOfflineDialog(BuildContext context, OrderProvider orderProvider) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final pendingCount = orderProvider.offlineOrders.length;
            
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: AppTheme.borderSubtle),
              ),
              title: Row(
                children: [
                  Icon(
                    orderProvider.isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                    color: orderProvider.isOffline ? Colors.redAccent : AppTheme.accentAmber,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isAr ? 'إدارة وضع الاتصال' : 'Connection Mode Manager',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Offline Switch
                    SwitchListTile(
                      activeColor: Colors.redAccent,
                      inactiveTrackColor: AppTheme.borderSubtle,
                      title: Text(
                        isAr ? 'الوضع دون اتصال (Offline)' : 'Offline Mode',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        isAr
                            ? 'تفعيل حفظ الطلبيات محلياً على الجهاز'
                            : 'Enable saving orders locally on this device',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                      value: orderProvider.isOffline,
                      onChanged: (val) async {
                        await orderProvider.toggleOffline(val);
                        setDialogState(() {});
                      },
                    ),
                    const Divider(height: 24),
                    
                    // Offline Queue Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isAr ? 'الطلبيات في الانتظار:' : 'Pending Offline Orders:',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: pendingCount > 0 ? Colors.orange.shade800 : AppTheme.borderSubtle,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$pendingCount',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    
                    if (pendingCount > 0) ...[
                      // List of pending orders
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: pendingCount,
                          itemBuilder: (context, index) {
                            final order = orderProvider.offlineOrders[index];
                            final cust = order.customerName?.isNotEmpty == true
                                ? order.customerName
                                : (isAr ? 'زبون غير مسمى' : 'Unnamed Customer');
                            return Card(
                              color: AppTheme.surfaceElevated,
                              margin: const EdgeInsets.only(bottom: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: AppTheme.borderSubtle),
                              ),
                              child: ListTile(
                                dense: true,
                                title: Text(cust!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  isAr 
                                      ? 'أقمشة: ${order.fabrics.length} | ${order.isDraft ? "مسودة" : "طلب"}'
                                      : 'Fabrics: ${order.fabrics.length} | ${order.isDraft ? "Draft" : "Order"}',
                                  style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                ),
                                onTap: () async {
                                  Navigator.of(dialogCtx).pop();
                                  orderProvider.loadOrder(order);
                                  await orderProvider.removeOfflineOrder(order.id);
                                  setTab(2);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isAr 
                                            ? 'تم تحميل الطلبية للمعاينة والتعديل ✓' 
                                            : 'Order loaded for preview and editing ✓',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.visibility_rounded, color: AppTheme.accentAmber, size: 16),
                                      onPressed: () => _showOfflineOrderDetails(context, order),
                                      tooltip: isAr ? 'معاينة المحتوى' : 'Preview Details',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                                      onPressed: () async {
                                        await orderProvider.removeOfflineOrder(order.id);
                                        setDialogState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Sync Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: orderProvider.isSyncing || orderProvider.isOffline
                              ? null 
                              : () async {
                                  final success = await orderProvider.syncOfflineOrders();
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isAr ? 'تمت مزامنة جميع الطلبيات بنجاح! ✓' : 'All orders synced successfully! ✓'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    Navigator.of(dialogCtx).pop();
                                  } else {
                                    setDialogState(() {});
                                  }
                                },
                          icon: orderProvider.isSyncing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.sync_rounded, size: 16),
                          label: Text(
                            orderProvider.isOffline 
                                ? (isAr ? 'قم بإيقاف وضع الاوفلاين للمزامنة' : 'Turn off offline to sync')
                                : (isAr ? 'مزامنة مع السيرفر الآن' : 'Sync with Server Now'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentAmber,
                            foregroundColor: AppTheme.surfaceDark,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      if (orderProvider.error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          orderProvider.error!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                        ),
                      ],
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          isAr ? 'لا توجد طلبات محفوظة دون اتصال حالياً.' : 'No offline orders stored.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(isAr ? 'إغلاق' : 'Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showOfflineOrderDetails(BuildContext context, Order order) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    
    double totalPrice = 0.0;
    int totalCylinders = 0;
    double totalMeters = 0.0;
    for (final fabric in order.fabrics) {
      final fabricQty = fabric.sequence.fold(0.0, (sum, val) => sum + val);
      totalPrice += fabricQty * fabric.price;
      totalCylinders += fabric.sequence.length;
      if (fabric.unit != 'kg') totalMeters += fabricQty;
    }

    final isQuickOrder = order.fabrics.isEmpty && order.voiceNoteBase64 != null && order.voiceNoteBase64!.isNotEmpty;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppTheme.borderSubtle),
          ),
          title: Row(
            children: [
              Icon(Icons.assignment_outlined, color: AppTheme.accentAmber),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  order.customerName?.isNotEmpty == true
                      ? '${isAr ? "طلب:" : "Order:"} ${order.customerName}'
                      : (isAr ? 'طلب غير مسمى' : 'Unnamed Order'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isAr ? 'نوع الطلب:' : 'Order Type:',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                            Text(
                              isQuickOrder 
                                  ? (isAr ? 'طلب صوتي سريع ⚡' : 'Quick Voice Order ⚡')
                                  : (order.isDraft 
                                      ? (isAr ? 'مسودة طلبيّة 📁' : 'Order Draft 📁')
                                      : (isAr ? 'طلب عادي 📄' : 'Standard Order 📄')),
                              style: TextStyle(
                                fontSize: 12, 
                                fontWeight: FontWeight.bold,
                                color: isQuickOrder ? Colors.purpleAccent : AppTheme.accentAmber,
                              ),
                            ),
                          ],
                        ),
                        if (!isQuickOrder) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isAr ? 'عدد الأسطوانات/اللفات:' : 'Total Cylinders/Rolls:',
                                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                              Text(
                                '$totalCylinders ${isAr ? "أسطوانة" : "Cylinders"}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isAr ? 'إجمالي الأمتار:' : 'Total Meters:',
                                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                              Text(
                                '${totalMeters.toStringAsFixed(1)} م',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isAr ? 'المجموع الإجمالي:' : 'Total Price:',
                                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                              Text(
                                '${totalPrice.toStringAsFixed(1)} د.ج',
                                style: TextStyle(
                                  fontSize: 14, 
                                  fontWeight: FontWeight.bold, 
                                  color: AppTheme.accentAmber,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Voice Player Section
                  if (order.voiceNoteBase64 != null && order.voiceNoteBase64!.isNotEmpty) ...[
                    Text(
                      isAr ? 'التسجيل الصوتي المرفق:' : 'Attached Voice Note:',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: OrderVoiceNotePlayer(base64String: order.voiceNoteBase64!),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Fabrics Section (if normal order)
                  if (!isQuickOrder) ...[
                    Text(
                      isAr ? 'محتويات الأقمشة:' : 'Fabric Content:',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: order.fabrics.length,
                      itemBuilder: (context, index) {
                        final fabric = order.fabrics[index];
                        
                        final List<String> lengthStrings = [];
                        fabric.lengths.forEach((len, mult) {
                          lengthStrings.add('$len${fabric.unit == "kg" ? "kg" : "m"}${mult > 1 ? " (x$mult)" : ""}');
                        });
                        
                        final fabricQty = fabric.sequence.fold(0.0, (sum, val) => sum + val);
                        final fabricPrice = fabricQty * fabric.price;
                        
                        return Card(
                          color: AppTheme.surfaceElevated,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppTheme.borderSubtle),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      fabric.fabricType.isNotEmpty ? fabric.fabricType : (isAr ? 'نوع غير محدد' : 'Unknown Fabric'),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${fabricPrice.toStringAsFixed(1)} د.ج',
                                      style: TextStyle(fontSize: 12, color: AppTheme.accentAmber, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Per-fabric meters + rolls row
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${isAr ? "سعر الوحدة" : "Unit Price"}: ${fabric.price.toStringAsFixed(1)} د.ج/${fabric.unit}',
                                        style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${isAr ? "الأمتار الكلية" : "Total Meters"}: ${fabricQty.toStringAsFixed(1)} ${fabric.unit == "kg" ? "kg" : "م"}',
                                      style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '${isAr ? "اللفات" : "Rolls"}: ${fabric.sequence.length}',
                                      style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Text(
                                  isAr ? 'المقاسات والتكرار:' : 'Lengths & Quantities:',
                                  style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: lengthStrings.map((str) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceDark.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppTheme.borderSubtle),
                                      ),
                                      child: Text(
                                        str,
                                        style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(isAr ? 'إغلاق' : 'Close'),
            ),
          ],
        );
      },
    );
  }
}
