import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import '../providers/language_provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../services/firestore_service.dart';
import '../providers/order_provider.dart';
import '../utils/payment_dialog.dart';
import 'quick_subtotal_dialog.dart';

/// Card widget displaying a complete order with fabric entries,
/// lengths, multipliers, and an optional action button.
class OrderCard extends StatelessWidget {
  final Order order;
  final bool showDoneButton;
  final bool showStatus;
  final VoidCallback? onDone;
  final VoidCallback? onRestore;
  final VoidCallback? onDelete;
  final VoidCallback? onResume;
  final bool isSent;

  const OrderCard({
    super.key,
    required this.order,
    this.showDoneButton = false,
    this.showStatus = false,
    this.onDone,
    this.onRestore,
    this.onDelete,
    this.onResume,
    this.isSent = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd – HH:mm');

    final isAr = order.receiverName.isEmpty;
    final isOrangeDraft = order.isDraft;
    final isQuickOrder = order.fabrics.isEmpty && order.voiceNoteBase64 != null && order.voiceNoteBase64!.isNotEmpty;

    return Card(
      color: isOrangeDraft
          ? Colors.orange.withValues(alpha: 0.05)
          : (isQuickOrder ? Colors.purple.withOpacity(0.06) : null),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOrangeDraft
              ? Colors.orange.withValues(alpha: 0.4)
              : (isQuickOrder ? Colors.purple.withOpacity(0.35) : AppTheme.borderSubtle),
          width: (isOrangeDraft || isQuickOrder) ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isOrangeDraft
                        ? Colors.orange.withValues(alpha: 0.12)
                        : (isQuickOrder
                            ? Colors.purple.withOpacity(0.15)
                            : AppTheme.accentAmber.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isOrangeDraft
                        ? Icons.folder_shared_rounded
                        : (isQuickOrder ? Icons.bolt_rounded : Icons.receipt_long_rounded),
                    color: isOrangeDraft
                        ? Colors.orange
                        : (isQuickOrder ? Colors.purpleAccent : AppTheme.accentAmber),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOrangeDraft
                            ? (isSent
                                ? 'تنبيه: مسودة مرسلة (Alert: Sent Draft)'
                                : 'تنبيه: مسودة واردة (Alert: Incoming Draft)')
                            : (isSent
                                ? 'إلى (To): ${order.receiverName}'
                                : 'من (From): ${order.senderName}'),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isOrangeDraft
                              ? Colors.orange
                              : (isQuickOrder ? Colors.purpleAccent : AppTheme.textPrimary),
                        ),
                      ),
                      if (isOrangeDraft) ...[
                        const SizedBox(height: 2),
                        Text(
                          isSent
                              ? 'المستلم (Receiver): ${order.receiverName}'
                              : 'المرسل (Sender): ${order.senderName}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                      if (order.customerName != null && order.customerName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'الزبون: ${order.customerName}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accentAmber,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        dateFormat.format(order.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      // ── Status badge + action buttons (history mode) ──
                      if (showStatus) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _StatusBadge(status: order.status),
                            const Spacer(),
                            if (onRestore != null) ...[
                              const SizedBox(width: 6),
                              IconButton(
                                icon: Icon(Icons.restore_rounded, color: AppTheme.accentAmber, size: 18),
                                tooltip: 'إعادة فتح الطلب',
                                onPressed: onRestore,
                                style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.surfaceElevated,
                                  padding: const EdgeInsets.all(4),
                                  minimumSize: const Size(32, 32),
                                ),
                              ),
                            ],
                            if (onDelete != null) ...[
                              const SizedBox(width: 6),
                              IconButton(
                                icon: Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 18),
                                tooltip: 'حذف الطلب نهائياً',
                                onPressed: onDelete,
                                style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.errorSurface,
                                  padding: const EdgeInsets.all(4),
                                  minimumSize: const Size(32, 32),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),


            if (isQuickOrder) ...[
              const SizedBox(height: 16),
              // Dedicated Premium Voice Player for Quick Order
              _QuickOrderVoiceNotePlayer(base64String: order.voiceNoteBase64!),
            ] else ...[
              const SizedBox(height: 16),
              Divider(color: AppTheme.borderSubtle, height: 1),
              const SizedBox(height: 16),

              // ─── Fabric Entries ────────────────────────────────
              ...order.fabrics.asMap().entries.map((entry) {
                final idx = entry.key;
                final fabric = entry.value;
                return _FabricSection(
                  fabric: fabric,
                  index: idx,
                  isLast: idx == order.fabrics.length - 1,
                  onTransferFabric: (!showStatus && order.status == 'pending')
                      ? () => _showTransferSingleFabricDialog(context, order, idx)
                      : null,
                );
              }),

              // ─── Order Summary Boxes ────────────────────────────
              Builder(
                builder: (context) {
                  double totalMeters = 0.0;
                  double totalKgs = 0.0;
                  double totalYards = 0.0;
                  int totalCylinders = 0;
                  double totalPrice = 0.0;

                  for (final fabric in order.fabrics) {
                    final fabricQty = fabric.sequence.fold(0.0, (sum, val) => sum + val);
                    totalCylinders += fabric.sequence.length;
                    totalPrice += fabricQty * fabric.price;
                    if (fabric.unit == 'kg') {
                      totalKgs += fabricQty;
                    } else if (fabric.unit == 'yard') {
                      totalYards += fabricQty;
                    } else {
                      totalMeters += fabricQty;
                    }
                  }

                  List<String> qtyParts = [];
                  if (totalMeters > 0) {
                    qtyParts.add('${totalMeters.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} m');
                  }
                  if (totalKgs > 0) {
                    qtyParts.add('${totalKgs.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} kg');
                  }
                  if (totalYards > 0) {
                    qtyParts.add('${totalYards.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} yd');
                  }
                  String qtyText = qtyParts.isEmpty ? '0' : qtyParts.join(' + ');

                  final formattedPrice = NumberFormat('#,##0.##', 'en_US').format(totalPrice);

                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'عدد الأقماش',
                                  style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${order.fabrics.length}',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 24, color: AppTheme.borderSubtle),
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'إجمالي الأسطوانات',
                                  style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$totalCylinders',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 24, color: AppTheme.borderSubtle),
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'إجمالي الكمية',
                                  style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    qtyText,
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 24, color: AppTheme.borderSubtle),
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'إجمالي السعر',
                                  style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '$formattedPrice د.ج',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accentAmber),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              // Voice Note Player
              if (order.voiceNoteBase64 != null && order.voiceNoteBase64!.isNotEmpty)
                OrderVoiceNotePlayer(base64String: order.voiceNoteBase64!),

              // ─── Payment Status Bar ──────────────────────────────
              if (!order.isDraft) ...[
                const SizedBox(height: 12),
                _PaymentStatusBar(order: order),
              ],
            ],

            // ─── Done/Resume/Recall/Merge Buttons ─────────────────────
            if (showDoneButton || onResume != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (!showStatus && order.status == 'pending') ...[
                    IconButton(
                      icon: const Icon(Icons.merge_type_rounded, size: 20),
                      color: AppTheme.accentAmber,
                      tooltip: 'دمج مع طلبية أخرى',
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.accentAmber.withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.all(10),
                      ),
                      onPressed: () => _showMergeDialog(context, order),
                    ),
                    if ((order.mergedHistory != null && order.mergedHistory!.isNotEmpty) ||
                        (order.customerName ?? '').contains('+')) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.call_split_rounded, size: 20),
                        color: Colors.orange,
                        tooltip: 'تفكيك الطلبية عن اختها',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.orange.withValues(alpha: 0.15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.all(10),
                        ),
                        onPressed: () => _showUnmergeDialog(context, order),
                      ),
                    ],
                    const SizedBox(width: 8),
                  ],
                  if (isSent && onResume != null) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onResume,
                        icon: const Icon(Icons.edit_rounded, size: 20),
                        label: const Text('تعديل / سحب  Edit / Recall'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentAmber,
                          foregroundColor: AppTheme.surfaceDark,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ] else ...[
                    if (isOrangeDraft && onResume != null) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onResume,
                          icon: const Icon(Icons.play_arrow_rounded, size: 16),
                          label: const Text('استئناف  Resume'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                    if (!isOrangeDraft && showDoneButton) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onDone,
                          icon: const Icon(Icons.check_circle_rounded, size: 20),
                          label: const Text('تم  Done'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: AppTheme.surfaceDark,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Payment Status Bar ───────────────────────────────────────────────────
class _PaymentStatusBar extends StatelessWidget {
  final Order order;
  const _PaymentStatusBar({required this.order});

  @override
  Widget build(BuildContext context) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    final total = order.computedTotal;
    final paid = order.paidAmount ?? 0.0;
    final balance = order.balanceDue;
    final progress = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;

    Color statusColor;
    String statusLabel;
    switch (order.paymentStatus) {
      case 'paid':
        statusColor = AppTheme.success;
        statusLabel = isAr ? 'مدفوع ✅' : 'Paid ✅';
        break;
      case 'partial':
        statusColor = Colors.orange;
        statusLabel = isAr ? 'دفع جزئي 🔶' : 'Partial 🔶';
        break;
      default:
        statusColor = AppTheme.error;
        statusLabel = isAr ? 'لم يُدفع ❌' : 'Unpaid ❌';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.payments_rounded, size: 14, color: statusColor),
                  const SizedBox(width: 6),
                  Text(
                    isAr ? 'حالة الدفع:' : 'Payment:',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                  const SizedBox(width: 6),
                  Text(statusLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                ],
              ),
              GestureDetector(
                onTap: () => showPaymentDialog(context, order),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, size: 11, color: AppTheme.accentAmber),
                      const SizedBox(width: 4),
                      Text(
                        isAr ? 'تسجيل' : 'Pay',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.accentAmber),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (order.paymentStatus != 'unpaid') ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${paid.toStringAsFixed(0)} / ${total.toStringAsFixed(0)} د.ج',
                  style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                ),
                Text(
                  balance > 0.5
                      ? '${isAr ? "متبقي" : "Due"}: ${balance.toStringAsFixed(0)} د.ج'
                      : balance < -0.5
                          ? '${isAr ? "باقي للزبون" : "Change"}: ${balance.abs().toStringAsFixed(0)} د.ج'
                          : '',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: balance > 0.5 ? AppTheme.error : Colors.tealAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppTheme.borderSubtle,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

void _showMergeDialog(BuildContext context, Order currentOrder) {
  final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    final firestoreService = FirestoreService();
    final isAr = context.tr('tab_orders') == 'الطلبيات';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StreamBuilder<List<Order>>(
          stream: firestoreService.streamOrdersForReceiver(authProvider.user!.uid),
          builder: (context, snapshot) {
            final orders = (snapshot.data ?? [])
                .where((o) => o.id != currentOrder.id && o.status == 'pending')
                .toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAr ? 'دمج مع طلبية أخرى' : 'Merge with another order',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isAr
                        ? 'اختر الطلبية التي تود دمج محتوياتها وأقماشها مع هذه الطلبية:'
                        : 'Select an order to merge into this order:',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: orders.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                isAr ? 'لا توجد طلبات معلقة أخرى للدمج' : 'No other pending orders to merge',
                                style: TextStyle(color: AppTheme.textMuted),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: orders.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final srcOrder = orders[idx];
                              final fabCount = srcOrder.fabrics.length;
                              final custName = srcOrder.customerName ?? (isAr ? 'بدون اسم' : 'No customer');

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.accentAmber.withValues(alpha: 0.2),
                                  child: Icon(Icons.merge_type_rounded, color: AppTheme.accentAmber, size: 20),
                                ),
                                title: Text(
                                  'الزبون: $custName',
                                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'من: ${srcOrder.senderName} • $fabCount نوع أقمشة',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accentAmber,
                                    foregroundColor: AppTheme.surfaceDark,
                                  ),
                                  onPressed: () {
                                    _showMergeOptionsChoice(context, currentOrder, srcOrder, isAr, ctx);
                                  },
                                  child: Text(isAr ? 'خيارات الدمج' : 'Merge Options'),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showMergeOptionsChoice(BuildContext context, Order currentOrder, Order srcOrder, bool isAr, BuildContext dialogCtx) {
    final firestoreService = FirestoreService();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isAr ? 'اختر طريقة الدمج' : 'Select Merge Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.merge_type_rounded, color: AppTheme.accentAmber),
              title: Text(isAr ? 'دمج الطلبية بالكامل' : 'Merge Full Order', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(isAr ? 'دمج جميع الأقمشة والكميات وإلغاء الطلبية المصدر' : 'Merge all fabrics and remove source order'),
              onTap: () async {
                Navigator.pop(ctx);
                Navigator.pop(dialogCtx);
                final messenger = ScaffoldMessenger.of(context);
                await firestoreService.mergeOrders(currentOrder, srcOrder);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(isAr ? 'تم دمج الطلبيتين بالكامل بنجاح ✓' : 'Orders merged successfully ✓'),
                    backgroundColor: AppTheme.successSurface,
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.checklist_rounded, color: AppTheme.accentAmber),
              title: Text(isAr ? 'دمج/نقل أقمشة محددة' : 'Transfer Specific Fabrics', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(isAr ? 'اختر أقمشة معينة لنقلها دون دمج كامل الطلبية' : 'Select specific fabrics to move'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pop(dialogCtx);
                _showSelectFabricsToMergeDialog(context, currentOrder, srcOrder, isAr);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSelectFabricsToMergeDialog(BuildContext context, Order targetOrder, Order sourceOrder, bool isAr) {
    final selectedIndices = <int>{};
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAr ? 'اختر الأقمشة للدمج والنقل' : 'Select Fabrics to Transfer',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAr
                        ? 'اختر الأقمشة المراد نقلها من طلبية "${sourceOrder.customerName ?? "المصدر"}" إلى هذه الطلبية:'
                        : 'Select fabrics to transfer from "${sourceOrder.customerName ?? "Source"}" to this order:',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: sourceOrder.fabrics.length,
                      separatorBuilder: (_, __) => Divider(color: AppTheme.borderSubtle, height: 1),
                      itemBuilder: (context, idx) {
                        final fabric = sourceOrder.fabrics[idx];
                        final isSelected = selectedIndices.contains(idx);
                        final totalQty = fabric.sequence.fold(0.0, (sum, val) => sum + val);

                        return CheckboxListTile(
                          value: isSelected,
                          activeColor: AppTheme.accentAmber,
                          checkColor: AppTheme.surfaceDark,
                          title: Text(
                            fabric.fabricType,
                            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'الكمية: ${totalQty.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} ${fabric.unit} (${fabric.sequence.length} ثوب)',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                selectedIndices.add(idx);
                              } else {
                                selectedIndices.remove(idx);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: Text(isAr ? 'تأكيد نقل ودمج الأقمشة المحددة' : 'Transfer Selected Fabrics'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentAmber,
                        foregroundColor: AppTheme.surfaceDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: selectedIndices.isEmpty
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await FirestoreService().transferFabricsBetweenOrders(
                                sourceOrder: sourceOrder,
                                targetOrder: targetOrder,
                                fabricIndicesToTransfer: selectedIndices.toList(),
                              );
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isAr ? 'تم نقل الأقمشة المحددة ودمجها بنجاح ✓' : 'Fabrics transferred successfully ✓',
                                  ),
                                  backgroundColor: AppTheme.successSurface,
                                ),
                              );
                            },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTransferSingleFabricDialog(BuildContext context, Order sourceOrder, int fabricIndex) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    final fabricToTransfer = sourceOrder.fabrics[fabricIndex];
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    final firestoreService = FirestoreService();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StreamBuilder<List<Order>>(
        stream: firestoreService.streamOrdersForReceiver(authProvider.user?.uid ?? ''),
        builder: (context, snapshot) {
          final pendingOrders = (snapshot.data ?? [])
              .where((o) => o.id != sourceOrder.id && o.status == 'pending' && !o.isDraft)
              .toList();

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isAr
                              ? 'نقل قماش "${fabricToTransfer.fabricType}" إلى طلبية أخرى'
                              : 'Transfer "${fabricToTransfer.fabricType}" to another order',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAr ? 'اختر الطلبية الهدف لنقل هذا القماش إليها:' : 'Select target order to move this fabric to:',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: pendingOrders.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                isAr ? 'لا توجد طلبات معلقة أخرى متاحة' : 'No other pending orders available',
                                style: TextStyle(color: AppTheme.textMuted),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: pendingOrders.length,
                            separatorBuilder: (_, __) => Divider(color: AppTheme.borderSubtle, height: 1),
                            itemBuilder: (context, idx) {
                              final targetOrder = pendingOrders[idx];
                              final custName = targetOrder.customerName ?? (isAr ? 'بدون اسم' : 'No customer');

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.accentAmber.withValues(alpha: 0.2),
                                  child: Icon(Icons.swap_horiz_rounded, color: AppTheme.accentAmber, size: 20),
                                ),
                                title: Text(
                                  'الطلبية: $custName',
                                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'من: ${targetOrder.senderName} • ${targetOrder.fabrics.length} أقمشة',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accentAmber,
                                    foregroundColor: AppTheme.surfaceDark,
                                  ),
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    Navigator.pop(ctx);
                                    await firestoreService.transferFabricsBetweenOrders(
                                      sourceOrder: sourceOrder,
                                      targetOrder: targetOrder,
                                      fabricIndicesToTransfer: [fabricIndex],
                                    );
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isAr
                                              ? 'تم نقل قماش "${fabricToTransfer.fabricType}" إلى طلبية "$custName" بنجاح ✓'
                                              : 'Transferred "${fabricToTransfer.fabricType}" to "$custName" ✓',
                                        ),
                                        backgroundColor: AppTheme.successSurface,
                                      ),
                                    );
                                  },
                                  child: Text(isAr ? 'نقل هنا' : 'Transfer Here'),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showUnmergeDialog(BuildContext context, Order currentOrder) {
  final firestoreService = FirestoreService();
  final isAr = context.tr('tab_orders') == 'الطلبيات';

  List<String> customerNames = [];
  if (currentOrder.mergedHistory != null && currentOrder.mergedHistory!.isNotEmpty) {
    customerNames = currentOrder.mergedHistory!
        .map((h) => (h['customerName'] as String? ?? '').trim())
        .where((name) => name.isNotEmpty)
        .toList();
  } else {
    customerNames = (currentOrder.customerName ?? '')
        .split('+')
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toList();
  }

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      title: Row(
        children: [
          const Icon(Icons.call_split_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          Text(isAr ? 'تفكيك الطلبية' : 'Unmerge Order'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr
                ? 'هل ترغب في تفكيك هذه الطلبية المدمجة وإعادتها كطلبيات منفصلة لكل زبون؟'
                : 'Do you want to split this merged order back into separate orders for each customer?',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text(
            isAr ? 'الطلبيات الناتجة:' : 'Resulting Orders:',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          ...customerNames.map((name) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.person_rounded, size: 16, color: AppTheme.accentAmber),
                const SizedBox(width: 6),
                Text('طلب الزبون: $name', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              ],
            ),
          )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(isAr ? 'إلغاء' : 'Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            Navigator.of(ctx).pop();
            await firestoreService.unmergeOrder(currentOrder);
            messenger.showSnackBar(
              SnackBar(
                content: Text(isAr ? 'تم تفكيك الطلبية وإعادة فصلها بنجاح ✓' : 'Orders separated successfully ✓'),
                backgroundColor: AppTheme.successSurface,
              ),
            );
          },
          child: Text(isAr ? 'تفكيك الآن' : 'Unmerge Now'),
        ),
      ],
    ),
  );
}

class _FabricSection extends StatelessWidget {
  final FabricEntry fabric;
  final int index;
  final bool isLast;
  final VoidCallback? onTransferFabric;

  const _FabricSection({
    required this.fabric,
    required this.index,
    required this.isLast,
    this.onTransferFabric,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fabric type label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.texture_rounded,
                  size: 16,
                  color: AppTheme.accentAmberLight,
                ),
                const SizedBox(width: 8),
                Text(
                  fabric.fabricType,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            if (onTransferFabric != null)
              InkWell(
                onTap: onTransferFabric,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentAmber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz_rounded, size: 14, color: AppTheme.accentAmber),
                      const SizedBox(width: 4),
                      Text(
                        'نقل القماش',
                        style: TextStyle(fontSize: 11, color: AppTheme.accentAmber, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Lengths with multipliers
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (fabric.lengths.entries.toList()..sort((a, b) {
            final double valA = double.tryParse(a.key) ?? 0.0;
            final double valB = double.tryParse(b.key) ?? 0.0;
            return valB.compareTo(valA);
          })).map((e) {
            final length = e.key;
            final multiplier = e.value;
            final displayLength = double.tryParse(length);
            final lengthText = displayLength != null &&
                    displayLength == displayLength.roundToDouble()
                ? displayLength.toInt().toString()
                : length;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.borderSubtle,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lengthText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (multiplier > 1) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.accentAmber.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '×$multiplier',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.accentAmberLight,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 12),

        // Per-fabric summary bar
        Builder(
          builder: (context) {
            final totalQuantity = fabric.sequence.fold(0.0, (sum, val) => sum + val);
            final totalPrice = totalQuantity * fabric.price;
            final formattedPrice = NumberFormat('#,##0.##', 'en_US').format(totalPrice);
            final formattedQty = totalQuantity == totalQuantity.roundToDouble()
                ? totalQuantity.toInt().toString()
                : totalQuantity.toStringAsFixed(1);
            final rollCount = fabric.sequence.length;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accentAmber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.layers_rounded, size: 15, color: AppTheme.accentAmber),
                      const SizedBox(width: 6),
                      Text(
                        '$rollCount أسطوانة',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '  •  ',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                      Text(
                        '$formattedQty م',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentAmberLight,
                        ),
                      ),
                    ],
                  ),
                  if (fabric.price > 0)
                    Text(
                      '$formattedPrice د.ج',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.accentAmber,
                      ),
                    ),
                ],
              ),
            );
          },
        ),

        if (!isLast) ...[
          const SizedBox(height: 14),
          Divider(
            color: AppTheme.borderSubtle.withValues(alpha: 0.5),
            height: 1,
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDone = status == 'done';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDone
            ? AppTheme.successSurface
            : AppTheme.accentAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isDone ? 'تم ✓' : 'قيد الانتظار',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDone ? AppTheme.success : AppTheme.accentAmber,
        ),
      ),
    );
  }
}

class OrderVoiceNotePlayer extends StatefulWidget {
  final String base64String;

  const OrderVoiceNotePlayer({required this.base64String});

  @override
  State<OrderVoiceNotePlayer> createState() => _OrderVoiceNotePlayerState();
}

class _OrderVoiceNotePlayerState extends State<OrderVoiceNotePlayer> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _compSub;

  double _playbackRate = 1.0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _posSub = _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _durSub = _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _compSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
          _isPaused = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _compSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isPaused = true;
        });
      }
    } else {
      try {
        if (_isPaused) {
          await _audioPlayer.resume();
        } else {
          final bytes = base64Decode(widget.base64String);
          await _audioPlayer.stop();
          await _audioPlayer.play(BytesSource(Uint8List.fromList(bytes)));
        }
        await _audioPlayer.setPlaybackRate(_playbackRate);
        if (mounted) {
          setState(() {
            _isPlaying = true;
            _isPaused = false;
          });
        }
      } catch (e) {
        print('Playback error: $e');
      }
    }
  }

  String _formatDuration(Duration d) {
    final seconds = d.inSeconds;
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.accentAmber.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                  color: AppTheme.accentAmber,
                  size: 32,
                ),
                onPressed: _playPause,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2.0,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
                        activeTrackColor: AppTheme.accentAmber,
                        inactiveTrackColor: AppTheme.borderSubtle,
                        thumbColor: AppTheme.accentAmber,
                      ),
                      child: Slider(
                        value: _position.inMilliseconds.toDouble(),
                        max: _duration.inMilliseconds.toDouble().clamp(0.1, double.infinity),
                        onChanged: (val) async {
                          final target = Duration(milliseconds: val.toInt());
                          await _audioPlayer.seek(target);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [1.0, 1.3, 1.5, 2.0].map((rate) {
              final isSelected = _playbackRate == rate;
              return ChoiceChip(
                label: Text('${rate.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}x'),
                selected: isSelected,
                onSelected: (val) async {
                  if (val) {
                    setState(() => _playbackRate = rate);
                    await _audioPlayer.setPlaybackRate(rate);
                  }
                },
                selectedColor: AppTheme.accentAmber,
                backgroundColor: AppTheme.surfaceDark,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : AppTheme.accentAmber,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _QuickOrderVoiceNotePlayer extends StatefulWidget {
  final String base64String;

  const _QuickOrderVoiceNotePlayer({required this.base64String});

  @override
  State<_QuickOrderVoiceNotePlayer> createState() => _QuickOrderVoiceNotePlayerState();
}

class _QuickOrderVoiceNotePlayerState extends State<_QuickOrderVoiceNotePlayer> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _compSub;

  double _playbackRate = 1.0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _posSub = _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _durSub = _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _compSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
          _isPaused = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _compSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isPaused = true;
        });
      }
    } else {
      try {
        if (_isPaused) {
          await _audioPlayer.resume();
        } else {
          final bytes = base64Decode(widget.base64String);
          await _audioPlayer.stop();
          await _audioPlayer.play(BytesSource(Uint8List.fromList(bytes)));
        }
        await _audioPlayer.setPlaybackRate(_playbackRate);
        if (mounted) {
          setState(() {
            _isPlaying = true;
            _isPaused = false;
          });
        }
      } catch (e) {
        print('Playback error: $e');
      }
    }
  }

  Future<void> _rewind() async {
    final target = _position - const Duration(seconds: 2);
    await _audioPlayer.seek(target < Duration.zero ? Duration.zero : target);
  }

  Future<void> _fastForward() async {
    final target = _position + const Duration(seconds: 2);
    await _audioPlayer.seek(target > _duration ? _duration : target);
  }

  String _formatDuration(Duration d) {
    final seconds = d.inSeconds;
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          // Audio seek slider
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
              activeTrackColor: Colors.purpleAccent,
              inactiveTrackColor: Colors.purple.shade900.withOpacity(0.35),
              thumbColor: Colors.purpleAccent,
            ),
            child: Slider(
              value: _position.inMilliseconds.toDouble(),
              max: _duration.inMilliseconds.toDouble().clamp(0.1, double.infinity),
              onChanged: (val) async {
                final target = Duration(milliseconds: val.toInt());
                await _audioPlayer.seek(target);
              },
            ),
          ),
          
          // Slider Timers Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: const TextStyle(fontSize: 11, color: Colors.purpleAccent, fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(fontSize: 11, color: Colors.purpleAccent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Player controls Row: Rewind 2s, Play/Pause, Forward 2s
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rewind 2s
              IconButton(
                icon: const Icon(Icons.fast_rewind_rounded, color: Colors.purpleAccent, size: 28),
                onPressed: _rewind,
                tooltip: 'تراجع ثانيتين (Rewind 2s)',
              ),
              const SizedBox(width: 24),
              
              // Play/Pause
              GestureDetector(
                onTap: _playPause,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Colors.purpleAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purpleAccent,
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              
              // Forward 2s
              IconButton(
                icon: const Icon(Icons.fast_forward_rounded, color: Colors.purpleAccent, size: 28),
                onPressed: _fastForward,
                tooltip: 'تقدم ثانيتين (Forward 2s)',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Speed controls: 1x, 1.3x, 1.5x, 2x
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [1.0, 1.3, 1.5, 2.0].map((rate) {
              final isSelected = _playbackRate == rate;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text('${rate.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}x'),
                  selected: isSelected,
                  onSelected: (val) async {
                    if (val) {
                      setState(() => _playbackRate = rate);
                      await _audioPlayer.setPlaybackRate(rate);
                    }
                  },
                  selectedColor: Colors.purpleAccent,
                  backgroundColor: Colors.purple.shade900.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.purpleAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
