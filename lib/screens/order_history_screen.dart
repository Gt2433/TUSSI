import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Stream<List<Order>>? _ordersStream;
  String? _currentShopId;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shopId = context.watch<app_auth.AuthProvider>().appUser?.shopId ?? '';
    if (_ordersStream == null || _currentShopId != shopId) {
      _currentShopId = shopId;
      _ordersStream = _firestoreService.streamOrderHistory(shopId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _startDate != null ||
      _endDate != null;

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: _endDate ?? DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.accentAmber,
              onPrimary: Colors.black,
              surface: AppTheme.surfaceCard,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.accentAmber,
              onPrimary: Colors.black,
              surface: AppTheme.surfaceCard,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _startDate = null;
      _endDate = null;
    });
  }

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
    return StreamBuilder<List<Order>>(
      stream: _ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: AppTheme.accentAmber,
            ),
          );
        }

        if (snapshot.hasError && !snapshot.hasData) {
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

        // Apply Search (Customer Name or Fabric Type) & Date Range (Between Start & End)
        final query = _searchController.text.trim().toLowerCase();
        final filteredOrders = orders.where((order) {
          // 1. Search Query: Customer name OR Fabric name (type)
          if (query.isNotEmpty) {
            final custMatch = (order.customerName ?? '').toLowerCase().contains(query);
            final fabMatch = order.fabrics.any((f) => f.fabricType.toLowerCase().contains(query));
            final idMatch = order.id.toLowerCase().contains(query);
            if (!custMatch && !fabMatch && !idMatch) return false;
          }

          // 2. Date Range: between _startDate and _endDate
          final orderDate = order.completedAt ?? order.createdAt;
          if (_startDate != null) {
            final startOfDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day, 0, 0, 0);
            if (orderDate.isBefore(startOfDay)) return false;
          }
          if (_endDate != null) {
            final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59, 999);
            if (orderDate.isAfter(endOfDay)) return false;
          }

          return true;
        }).toList();

        return Column(
          children: [
            // ─── Search and Date Filter Controls ─────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: context.tr('search_customer_or_fabric'),
                        hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        prefixIcon: Icon(Icons.search_rounded, color: AppTheme.accentAmber, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Date Range Controls
                  Row(
                    children: [
                      // From Date
                      Expanded(
                        child: InkWell(
                          onTap: _pickStartDate,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              color: _startDate != null
                                  ? AppTheme.accentAmber.withValues(alpha: 0.15)
                                  : AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _startDate != null
                                    ? AppTheme.accentAmber
                                    : AppTheme.borderSubtle,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 13,
                                  color: _startDate != null ? AppTheme.accentAmber : AppTheme.textMuted,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    _startDate != null
                                        ? '${context.tr('date_from')}: ${DateFormat('yyyy/MM/dd').format(_startDate!)}'
                                        : context.tr('date_from'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: _startDate != null ? FontWeight.bold : FontWeight.normal,
                                      color: _startDate != null ? AppTheme.accentAmber : AppTheme.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // To Date
                      Expanded(
                        child: InkWell(
                          onTap: _pickEndDate,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              color: _endDate != null
                                  ? AppTheme.accentAmber.withValues(alpha: 0.15)
                                  : AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _endDate != null
                                    ? AppTheme.accentAmber
                                    : AppTheme.borderSubtle,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_available_rounded,
                                  size: 13,
                                  color: _endDate != null ? AppTheme.accentAmber : AppTheme.textMuted,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    _endDate != null
                                        ? '${context.tr('date_to')}: ${DateFormat('yyyy/MM/dd').format(_endDate!)}'
                                        : context.tr('date_to'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: _endDate != null ? FontWeight.bold : FontWeight.normal,
                                      color: _endDate != null ? AppTheme.accentAmber : AppTheme.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Reset Filters Button
                      if (_hasActiveFilters) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _resetFilters,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.refresh_rounded, size: 14, color: AppTheme.error),
                                const SizedBox(width: 3),
                                Text(
                                  context.tr('reset_filter'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Header status row (Count & Clear History)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Text(
                          _hasActiveFilters
                              ? '${filteredOrders.length} / ${orders.length} ${context.tr('completed_orders_suffix')}'
                              : '${orders.length} ${context.tr('completed_orders_suffix')}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _hasActiveFilters ? AppTheme.accentAmber : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _clearAllHistory,
                        icon: Icon(Icons.delete_sweep_rounded, color: AppTheme.error, size: 16),
                        label: Text(
                          context.tr('clear_all_history') ?? 'مسح السجل',
                          style: TextStyle(color: AppTheme.error, fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          backgroundColor: AppTheme.error.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Divider(height: 12, color: AppTheme.borderSubtle),

            // ─── Orders List or No Results ───────────────────────
            Expanded(
              child: orders.isEmpty
                  ? Center(
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
                    )
                  : filteredOrders.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted),
                                const SizedBox(height: 12),
                                Text(
                                  context.tr('no_matching_results'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextButton.icon(
                                  onPressed: _resetFilters,
                                  icon: Icon(Icons.refresh_rounded, size: 16),
                                  label: Text(context.tr('reset_filter')),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.accentAmber,
                                    backgroundColor: AppTheme.accentAmber.withValues(alpha: 0.12),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
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
                    ),
            ),
          ],
        );
      },
    );
  }
}
