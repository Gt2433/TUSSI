import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/language_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/order_card.dart';

/// Screen displaying completed order history.
/// Triggers client-side TTL cleanup on load for orders older than 30 days.
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _hasCleanedUp = false;

  @override
  void initState() {
    super.initState();
    _runCleanup();
  }

  Future<void> _runCleanup() async {
    if (_hasCleanedUp) return;
    _hasCleanedUp = true;

    try {
      final deletedCount = await _firestoreService.cleanupExpiredOrders();
      if (deletedCount > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.tr('expired_orders_deleted')} ($deletedCount)',
            ),
            backgroundColor: AppTheme.surfaceElevated,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (_) {
      // Silent cleanup failure - non-critical
    }
  }

  Future<void> _restoreOrder(String orderId) async {
    try {
      await _firestoreService.restoreOrder(orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 20),
              const SizedBox(width: 10),
              Text(context.tr('order_restored') ?? 'تمت استعادة الطلب إلى قائمة النشطة ✓'),
            ],
          ),
          backgroundColor: AppTheme.successSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorSurface,
        ),
      );
    }
  }

  Future<void> _deleteOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('delete') ?? 'حذف'),
        content: Text(context.tr('delete_order_confirm') ?? 'هل تريد حذف هذا الطلب نهائياً من السجل وقاعدة البيانات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text(context.tr('delete') ?? 'حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    try {
      await _firestoreService.deleteOrder(orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('order_deleted') ?? 'تم حذف الطلب بنجاح ✓'),
          backgroundColor: AppTheme.successSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorSurface,
        ),
      );
    }
  }

  Future<void> _clearAllHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('clear_all_history') ?? 'مسح السجل بالكامل'),
        content: Text(context.tr('clear_history_confirm') ?? 'هل أنت متأكد من مسح جميع الطلبيات المكتملة نهائياً؟ لا يمكن التراجع.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text(context.tr('clear_all_history') ?? 'مسح الكل'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    try {
      await _firestoreService.clearAllHistory();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('history_cleared') ?? 'تم مسح السجل بنجاح ✓'),
          backgroundColor: AppTheme.successSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorSurface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopId = context
        .watch<app_auth.AuthProvider>()
        .appUser
        ?.shopId ?? '';
    return StreamBuilder<List<Order>>(
      stream: _firestoreService.streamOrderHistory(shopId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: AppTheme.accentAmber,
            ),
          );
        }

        if (snapshot.hasError) {
          print('Firebase Error Details (History): \n${snapshot.error}');
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 48, color: AppTheme.error),
                const SizedBox(height: 12),
                Text(
                  context.tr('error_loading_history'),
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
                    Icons.history_rounded,
                    size: 56,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  context.tr('no_history_yet'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('completed_orders_appear_here'),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('auto_delete_30_days'),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    fontStyle: FontStyle.italic,
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
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Text(
                        '${orders.length} ${context.tr('completed_orders_suffix')}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _clearAllHistory,
                      icon: Icon(Icons.delete_sweep_rounded, color: AppTheme.error, size: 18),
                      label: Text(
                        context.tr('clear_all_history') ?? 'مسح السجل',
                        style: TextStyle(color: AppTheme.error, fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        backgroundColor: AppTheme.error.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              );
            }

            final order = orders[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Opacity(
                opacity: 0.85,
                child: OrderCard(
                  order: order,
                  showStatus: true,
                  onRestore: () => _restoreOrder(order.id),
                  onDelete: () => _deleteOrder(order.id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
