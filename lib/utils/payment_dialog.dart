import "package:flutter/material.dart";
import "../models/order_model.dart";
import "../providers/language_provider.dart";
import "../services/firestore_service.dart";
import "../theme/app_theme.dart";

/// Public payment dialog callable from any widget (OrderCard, PaymentsScreen, etc.)
void showPaymentDialog(BuildContext context, Order order) {
  final isAr = context.tr("tab_orders") == "\u0627\u0644\u0637\u0644\u0628\u064a\u0627\u062a";
  final firestoreService = FirestoreService();

  final totalCtrl = TextEditingController(text: order.computedTotal.toStringAsFixed(0));
  final paidCtrl = TextEditingController(
      text: order.paidAmount != null ? order.paidAmount!.toStringAsFixed(0) : "");

  double liveTotal = order.computedTotal;
  double livePaid = order.paidAmount ?? 0;

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setDlgState) {
        final balance = liveTotal - livePaid;
        Color balanceColor;
        String balanceLabel;
        IconData balanceIcon;
        if (balance > 0.5) {
          balanceColor = Colors.redAccent;
          balanceLabel = isAr
              ? "\u0627\u0644\u0645\u062a\u0628\u0642\u064a \u0639\u0644\u0649 \u0627\u0644\u0632\u0628\u0648\u0646: ${balance.toStringAsFixed(0)} \u062f.\u062c"
              : "Remaining: ${balance.toStringAsFixed(0)} DA";
          balanceIcon = Icons.arrow_downward_rounded;
        } else if (balance < -0.5) {
          balanceColor = Colors.tealAccent;
          balanceLabel = isAr
              ? "\u0627\u0644\u0628\u0627\u0642\u064a \u0644\u0644\u0632\u0628\u0648\u0646 (\u0641\u0643\u0629): ${balance.abs().toStringAsFixed(0)} \u062f.\u062c"
              : "Change to return: ${balance.abs().toStringAsFixed(0)} DA";
          balanceIcon = Icons.arrow_upward_rounded;
        } else {
          balanceColor = AppTheme.success;
          balanceLabel = isAr ? "\u0645\u062f\u0641\u0648\u0639 \u0628\u0627\u0644\u0643\u0627\u0645\u0644" : "Fully Paid";
          balanceIcon = Icons.check_circle_rounded;
        }

        String computedStatus;
        if (livePaid <= 0) {
          computedStatus = "unpaid";
        } else if (balance > 0.5) {
          computedStatus = "partial";
        } else {
          computedStatus = "paid";
        }

        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppTheme.borderSubtle),
          ),
          title: Row(
            children: [
              Icon(Icons.payments_rounded, color: AppTheme.accentAmber),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAr ? "\u062a\u0633\u062c\u064a\u0644 / \u062a\u0639\u062f\u064a\u0644 \u0627\u0644\u062f\u0641\u0639" : "Record / Edit Payment",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (order.customerName?.isNotEmpty == true)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Icon(Icons.person_outline_rounded, size: 16, color: AppTheme.textMuted),
                        const SizedBox(width: 8),
                        Text(order.customerName!,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ]),
                    ),
                  Text(
                    isAr ? "\u0627\u0644\u0633\u0639\u0631 \u0627\u0644\u0646\u0647\u0627\u0626\u064a (\u0627\u062e\u062a\u064a\u0627\u0631\u064a):" : "Final Price (optional override):",
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: totalCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      filled: true, fillColor: AppTheme.surfaceElevated,
                      suffixText: "\u062f.\u062c",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.accentAmber, width: 2)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (v) => setDlgState(() => liveTotal = double.tryParse(v) ?? order.computedTotal),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAr ? "\u0627\u0644\u0645\u0628\u0644\u063a \u0627\u0644\u0645\u062f\u0641\u0648\u0639:" : "Amount Paid:",
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: paidCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      filled: true, fillColor: AppTheme.surfaceElevated,
                      suffixText: "\u062f.\u062c",
                      hintText: isAr ? "\u0623\u062f\u062e\u0644 \u0627\u0644\u0645\u0628\u0644\u063a..." : "Enter paid amount...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderSubtle)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.accentAmber, width: 2)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (v) => setDlgState(() => livePaid = double.tryParse(v) ?? 0),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: balanceColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: balanceColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(children: [
                      Icon(balanceIcon, color: balanceColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(balanceLabel,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: balanceColor)),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(isAr ? "\u0625\u0644\u063a\u0627\u0621" : "Cancel",
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final overriddenTotal = double.tryParse(totalCtrl.text.trim());
                final paidVal = double.tryParse(paidCtrl.text.trim()) ?? 0;
                final autoTotal = order.computedTotal;
                final finalPriceToSave =
                    (overriddenTotal != null && (overriddenTotal - autoTotal).abs() > 0.01)
                        ? overriddenTotal
                        : null;
                await firestoreService.updateOrderPayment(
                  orderId: order.id,
                  finalPrice: finalPriceToSave,
                  paidAmount: paidVal,
                  paymentStatus: computedStatus,
                );
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              icon: const Icon(Icons.save_rounded, size: 16),
              label: Text(isAr ? "\u062d\u0641\u0638" : "Save"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentAmber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      });
    },
  );
}