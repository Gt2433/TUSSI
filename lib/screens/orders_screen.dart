import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/language_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/order_card.dart';
import '../providers/order_provider.dart';
import 'home_screen.dart';

/// Screen showing pending orders assigned to (Inbox) or sent by (Sent) the current user.
/// Supports real-time updates, tab switching, completions, and recall/editing.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _markDone(Order order) async {
    try {
      await _firestoreService.markOrderDoneGroup(order);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: AppTheme.success, size: 20),
                const SizedBox(width: 10),
                Text(context.tr('order_moved_to_history')),
              ],
            ),
            backgroundColor: AppTheme.successSurface,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorSurface,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<app_auth.AuthProvider>();
    final uid = authProvider.user?.uid;
    final isAr = context.tr('tab_orders') == 'الطلبيات';

    if (uid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // ─── Custom TabBar ─────────────────────────────────
          Container(
            color: AppTheme.surfaceDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: AppTheme.accentAmber,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppTheme.surfaceDark,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: [
                  Tab(text: isAr ? 'الواردة (Inbox)' : 'Received'),
                  Tab(text: isAr ? 'المرسلة (Sent)' : 'Sent'),
                ],
              ),
            ),
          ),

          // ─── Tab Views ──────────────────────────────────────
          Expanded(
            child: TabBarView(
              children: [
                // 1. Incoming Tab (Received)
                _buildIncomingTab(uid),
                // 2. Outgoing Tab (Sent)
                _buildSentTab(uid),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingTab(String uid) {
    return StreamBuilder<List<Order>>(
      stream: _firestoreService.streamOrdersForReceiver(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: AppTheme.accentAmber,
            ),
          );
        }

        if (snapshot.hasError) {
          print('Firebase Error Details: \n${snapshot.error}');
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 48, color: AppTheme.error),
                const SizedBox(height: 12),
                Text(
                  context.tr('error_loading_orders'),
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Icon(
                    Icons.inbox_rounded,
                    size: 56,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  context.tr('no_orders_yet'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('new_orders_appear_here'),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              // Header
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${orders.length} ${context.tr('orders_count_suffix')}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentAmber,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.tr('live'),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              );
            }

            final order = orders[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OrderCard(
                order: order,
                showDoneButton: true,
                onDone: () => _confirmDone(context, order),
                onResume: () => _resumeOrder(context, order),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSentTab(String uid) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    return StreamBuilder<List<Order>>(
      stream: _firestoreService.streamOrdersForSender(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: AppTheme.accentAmber,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              context.tr('error_loading_orders'),
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Icon(
                    Icons.outbox_rounded,
                    size: 56,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isAr ? 'لا توجد طلبات مرسلة معلقة' : 'No sent pending orders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAr
                      ? 'الطلبيات أو المسودات التي أرسلتها ولم تجهز بعد ستظهر هنا'
                      : 'Orders or drafts you sent that are not done yet will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              // Header
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${orders.length} ${isAr ? "مرسلة معلقة" : "sent pending"}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentAmber,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.tr('live'),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              );
            }

            final order = orders[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OrderCard(
                order: order,
                isSent: true,
                onResume: () => _resumeSentOrder(context, order),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDone(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('confirm_completion')),
        content: Text(context.tr('order_entered_question')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr('not_yet')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _markDone(order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: AppTheme.surfaceDark,
            ),
            child: Text(context.tr('yes_done')),
          ),
        ],
      ),
    );
  }

  void _resumeOrder(BuildContext context, Order order) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'استئناف الطلبية' : 'Resume Order'),
        content: Text(isAr
            ? 'هل تود استئناف العمل على هذه الطلبية؟ سيتم سحبها من الطلبيات المعلقة وإضافتها كمسودة قابلة للتعديل في حسابك.'
            : 'Do you want to resume this order? It will be removed from the pending list and loaded as an editable draft in your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              
              // 1. Load into draft in OrderProvider
              final orderProvider = Provider.of<OrderProvider>(context, listen: false);
              orderProvider.loadOrder(order);
              
              // 2. Delete from pending in Firestore
              await _firestoreService.deleteOrderGroup(order);
              
              // 3. Switch to New Order tab
              if (context.mounted) {
                final homeState = context.findAncestorStateOfType<HomeScreenState>();
                homeState?.setTab(2); // Switch to New Order tab
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isAr ? 'تم استئناف الطلبية بنجاح ✓' : 'Order resumed successfully ✓'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentAmber,
              foregroundColor: AppTheme.surfaceDark,
            ),
            child: Text(isAr ? 'استئناف' : 'Resume'),
          ),
        ],
      ),
    );
  }

  void _resumeSentOrder(BuildContext context, Order order) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'تعديل وسحب الطلبية' : 'Recall & Edit Order'),
        content: Text(isAr
            ? 'هل تود سحب هذه الطلبية وتعديلها؟ سيتم مسحها من شاشات المستلمين وإعادتها كمسودة لتتمكن من التعديل عليها وإعادة إرسالها.'
            : 'Do you want to recall and edit this order? It will be deleted from the receivers\' screens and loaded back as a draft in your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              
              // 1. Load into draft in OrderProvider
              final orderProvider = Provider.of<OrderProvider>(context, listen: false);
              orderProvider.loadOrder(order);
              
              // 2. Delete from pending in Firestore
              await _firestoreService.deleteOrderGroup(order);
              
              // 3. Switch to New Order tab
              if (context.mounted) {
                final homeState = context.findAncestorStateOfType<HomeScreenState>();
                homeState?.setTab(2); // Switch to New Order tab
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isAr ? 'تم سحب الطلب وتعبئته للتعديل ✓' : 'Order recalled and loaded for editing ✓'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentAmber,
              foregroundColor: AppTheme.surfaceDark,
            ),
            child: Text(isAr ? 'سحب وتعديل' : 'Recall & Edit'),
          ),
        ],
      ),
    );
  }
}
