import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/language_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/payment_dialog.dart';
import 'package:intl/intl.dart';

/// Screen showing all orders with pending/partial payment status (الذمم المالية).
class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<app_auth.AuthProvider>();
    final uid = authProvider.user?.uid;
    final langProvider = context.watch<LanguageProvider>();
    final isAr = langProvider.languageCode == 'ar' || context.tr('tab_orders') == 'الطلبيات';
    final numberFormat = NumberFormat('#,##0', 'en_US');

    if (uid == null) return const Center(child: CircularProgressIndicator());

    return StreamBuilder<List<Order>>(
      stream: FirestoreService().streamDebtOrders(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.accentAmber),
          );
        }

        final orders = snapshot.data ?? [];
        final debtOrders = orders.where((o) => o.paymentStatus != 'paid').toList();

        if (debtOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 72,
                  color: AppTheme.success.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 16),
                Text(
                  isAr ? 'لا توجد ذمم مالية متبقية 🎉' : 'No outstanding debts 🎉',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAr ? 'جميع الطلبيات مدفوعة بالكامل' : 'All orders are fully paid',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
              ],
            ),
          );
        }

        double totalOwed = 0;
        double totalPaid = 0;
        for (final o in debtOrders) {
          totalOwed += o.computedTotal;
          totalPaid += o.paidAmount ?? 0;
        }
        final totalRemaining = totalOwed - totalPaid;

        return Column(
          children: [
            // ─── Summary Banner ──────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentAmber.withValues(alpha: 0.15),
                    AppTheme.surfaceElevated,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppTheme.accentAmber,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? 'إجمالي الذمم المالية المتبقية' : 'Total Outstanding Debts',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${numberFormat.format(totalRemaining)} د.ج',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: totalRemaining > 0 ? AppTheme.accentAmber : AppTheme.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${debtOrders.length} ${isAr ? "طلبية" : "orders"}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAr ? 'غير مسددة' : 'Unpaid',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ─── Cards List ─────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                itemCount: debtOrders.length,
                itemBuilder: (context, index) =>
                    _DebtOrderCard(order: debtOrders[index], isAr: isAr),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Debt Order Card Widget ───────────────────────────────────────────────
class _DebtOrderCard extends StatelessWidget {
  final Order order;
  final bool isAr;

  const _DebtOrderCard({required this.order, required this.isAr});

  Color get _statusColor {
    switch (order.paymentStatus) {
      case 'paid':
        return AppTheme.success;
      case 'partial':
        return Colors.orange;
      default:
        return AppTheme.error;
    }
  }

  String get _statusLabel {
    switch (order.paymentStatus) {
      case 'paid':
        return isAr ? 'مدفوع بالكامل ✅' : 'Paid ✅';
      case 'partial':
        return isAr ? 'دفع جزئي 🔶' : 'Partial 🔶';
      default:
        return isAr ? 'غير مدفوع ❌' : 'Unpaid ❌';
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0', 'en_US');
    final total = order.computedTotal;
    final paid = order.paidAmount ?? 0.0;
    final balance = order.balanceDue;
    final progress = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;
    final dateStr = DateFormat('yyyy/MM/dd').format(order.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _statusColor.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    order.paymentStatus == 'paid'
                        ? Icons.check_circle_rounded
                        : (order.paymentStatus == 'partial'
                            ? Icons.timelapse_rounded
                            : Icons.money_off_rounded),
                    color: _statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName?.isNotEmpty == true
                            ? order.customerName!
                            : (isAr ? 'زبون غير مسمى' : 'Unnamed Customer'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _statusColor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Amount Chips Row
            Row(
              children: [
                _AmountChip(
                  label: isAr ? 'الإجمالي' : 'Total',
                  value: '${numberFormat.format(total)} د.ج',
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 8),
                _AmountChip(
                  label: isAr ? 'المدفوع' : 'Paid',
                  value: '${numberFormat.format(paid)} د.ج',
                  color: AppTheme.success,
                ),
                const SizedBox(width: 8),
                _AmountChip(
                  label: balance > 0
                      ? (isAr ? 'المتبقي' : 'Remaining')
                      : (isAr ? 'الباقي له' : 'Change'),
                  value: '${numberFormat.format(balance.abs())} د.ج',
                  color: balance > 0 ? AppTheme.error : Colors.tealAccent,
                  bold: true,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAr ? 'نسبة السداد' : 'Payment Progress',
                  style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _statusColor),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: AppTheme.borderSubtle,
                valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
              ),
            ),

            const SizedBox(height: 14),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => showPaymentDialog(context, order),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: Text(isAr ? 'تسجيل / تعديل الدفع' : 'Record / Edit Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentAmber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Amount Chip Sub-Widget ────────────────────────────────────────────────
class _AmountChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _AmountChip({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 9, color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                  color: color == AppTheme.textMuted ? AppTheme.textPrimary : color,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

