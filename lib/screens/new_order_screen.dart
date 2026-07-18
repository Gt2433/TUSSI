import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/language_provider.dart';
import '../providers/order_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/fabric_entry_card.dart';
import '../widgets/send_order_dialog.dart';
import '../widgets/voice_note_recorder.dart';

/// Screen for building and sending a new order.
/// Supports multiple fabric entries with lengths and multipliers.
class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final TextEditingController _customerNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with one empty fabric entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OrderProvider>(context, listen: false);
      if (!provider.hasEntries) {
        provider.initNewOrder();
      }
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    super.dispose();
  }

  Future<void> _sendOrder() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);

    // Validate first
    final validationError = orderProvider.validateOrder();
    if (validationError != null) {
      _showSnackBar(validationError, isError: true);
      return;
    }

    // Show receiver selection dialog
    final selectedUsers = await SendOrderDialog.show(
      context,
      authProvider.user!.uid,
      shopId: authProvider.appUser?.shopId ?? '',
    );

    if (selectedUsers == null || selectedUsers.isEmpty || !mounted) return;

    // Send the order
    final success = await orderProvider.sendOrder(
      senderId: authProvider.user!.uid,
      senderName: authProvider.displayName,
      receiverIds: selectedUsers.map((u) => u.uid).toList(),
      receiverNames: selectedUsers.map((u) => u.displayName).toList(),
      customerName: _customerNameController.text.trim(),
      shopId: authProvider.appUser?.shopId ?? '',
    );

    if (mounted) {
      if (success) {
        _customerNameController.clear();
        final names = selectedUsers.map((u) => u.displayName).join(', ');
        _showSnackBar(
          '${context.tr('order_sent_to')} $names ✓',
          isError: false,
        );
      } else {
        _showSnackBar(
          orderProvider.error ?? context.tr('failed_send'),
          isError: true,
        );
      }
    }
  }

  Future<void> _sendDraft() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);

    // Validate first
    final validationError = orderProvider.validateOrder();
    if (validationError != null) {
      _showSnackBar(validationError, isError: true);
      return;
    }

    // Show receiver selection dialog in Single Select mode
    final selectedUsers = await SendOrderDialog.show(
      context,
      authProvider.user!.uid,
      shopId: authProvider.appUser?.shopId ?? '',
      isSingleSelect: true,
    );

    if (selectedUsers == null || selectedUsers.isEmpty || !mounted) return;
    final selectedUser = selectedUsers.first;

    // Send the draft (set isDraft to true)
    final success = await orderProvider.sendOrder(
      senderId: authProvider.user!.uid,
      senderName: authProvider.displayName,
      receiverIds: [selectedUser.uid],
      receiverNames: [selectedUser.displayName],
      customerName: _customerNameController.text.trim(),
      shopId: authProvider.appUser?.shopId ?? '',
      isDraft: true,
    );

    if (mounted) {
      if (success) {
        _customerNameController.clear();
        final isAr = context.tr('tab_orders') == 'الطلبيات';
        _showSnackBar(
          isAr 
              ? 'تم إرسال المسودة إلى ${selectedUser.displayName} ✓'
              : 'Draft sent to ${selectedUser.displayName} ✓',
          isError: false,
        );
      } else {
        _showSnackBar(
          orderProvider.error ?? context.tr('failed_send'),
          isError: true,
        );
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: isError ? AppTheme.error : AppTheme.success,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppTheme.errorSurface : AppTheme.successSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final isAr = context.tr('tab_orders') == 'الطلبيات';

    if (orderProvider.draftCustomerName != _customerNameController.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && orderProvider.draftCustomerName != _customerNameController.text) {
          _customerNameController.text = orderProvider.draftCustomerName;
        }
      });
    }

    return Stack(
      children: [
        // ─── Main Content ────────────────────────────────────
        CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Header info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.accentAmber.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppTheme.accentAmber,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.tr('new_order_instructions'),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.accentAmberLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customerNameController,
                          onChanged: (val) {
                            orderProvider.draftCustomerName = val;
                          },
                          decoration: InputDecoration(
                            labelText: context.tr('customer_name') ?? 'اسم الزبون (اختياري)',
                            hintText: context.tr('customer_hint') ?? 'أدخل اسم الزبون',
                            prefixIcon: const Icon(Icons.person_outline_rounded),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const VoiceNoteRecorder(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildOrderSummaryCard(context, orderProvider),
                  const SizedBox(height: 16),

                  // Fabric entry cards
                  ...orderProvider.fabricEntries.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FabricEntryCard(
                        key: ValueKey('fabric_${entry.key}'),
                        entryIndex: entry.key,
                        canRemove: orderProvider.fabricEntries.length > 1,
                      ),
                    );
                  }),

                  // Add another fabric button
                  OutlinedButton.icon(
                    onPressed: () => orderProvider.addFabricEntry(),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(context.tr('add_another_fabric')),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 52),
                      side: BorderSide(
                        color: AppTheme.accentAmber.withValues(alpha: 0.4),
                        width: 1.5,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),

        // ─── Send Order Button (Fixed Bottom) ────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark.withValues(alpha: 0.95),
              border: Border(
                top: BorderSide(color: AppTheme.borderSubtle),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Send Draft Button
                  Expanded(
                    flex: 4,
                    child: ElevatedButton.icon(
                      onPressed: orderProvider.isSending ? null : _sendDraft,
                      icon: const Icon(Icons.folder_shared_rounded, size: 18),
                      label: Text(
                        isAr ? 'أرسل المسودة' : 'Send Draft',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Send Order Button
                  Expanded(
                    flex: 5,
                    child: ElevatedButton.icon(
                      onPressed: orderProvider.isSending ? null : _sendOrder,
                      icon: orderProvider.isSending
                          ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.surfaceDark,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        orderProvider.isSending
                            ? context.tr('sending')
                            : context.tr('send_order'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummaryCard(BuildContext context, OrderProvider orderProvider) {
    final fabricEntries = orderProvider.fabricEntries;
    final grandTotalRolls = fabricEntries.fold<int>(0, (sum, entry) => sum + entry.sequence.length);

    final totalMeters = fabricEntries
        .where((e) => e.unit == 'meter')
        .fold<double>(0.0, (sum, e) => sum + e.sequence.fold<double>(0.0, (s, val) => s + val));

    final totalKgs = fabricEntries
        .where((e) => e.unit == 'kg')
        .fold<double>(0.0, (sum, e) => sum + e.sequence.fold<double>(0.0, (s, val) => s + val));

    final grandTotalPrice = fabricEntries.fold<double>(
      0.0,
      (sum, entry) {
        final qty = entry.sequence.fold<double>(0.0, (s, val) => s + val);
        return sum + (qty * entry.price);
      },
    );

    final formattedTotalPrice = NumberFormat('#,##0.##', 'en_US').format(grandTotalPrice);
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    final currency = isAr ? 'د.ج' : 'DA';

    // Build the quantity text
    String qtyText = '';
    if (totalMeters > 0 && totalKgs > 0) {
      qtyText = '${totalMeters.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} m + ${totalKgs.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} kg';
    } else if (totalMeters > 0) {
      qtyText = '${totalMeters.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} m';
    } else if (totalKgs > 0) {
      qtyText = '${totalKgs.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} kg';
    } else {
      qtyText = '0';
    }

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppTheme.accentAmber.withValues(alpha: 0.05),
      elevation: 0,
      child: InkWell(
        onTap: () => _showOrderSummaryDetailsSheet(context, orderProvider),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.accentAmber.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.summarize_rounded,
                    color: AppTheme.accentAmber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isAr ? 'إجمالي الطلبية' : 'Order Summary',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentAmberLight,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.zoom_in_rounded,
                    size: 16,
                    color: AppTheme.accentAmber.withValues(alpha: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  // Rolls Count
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          isAr ? 'اللفات' : 'Rolls',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.layers_rounded, size: 14, color: AppTheme.accentAmber),
                            const SizedBox(width: 4),
                            Text(
                              '$grandTotalRolls',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppTheme.borderSubtle),
                  // Total Quantity
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          isAr ? 'إجمالي الكمية' : 'Total Qty',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.straighten_rounded, size: 14, color: AppTheme.accentAmber),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                qtyText,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppTheme.borderSubtle),
                  // Total Price
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          isAr ? 'السعر الإجمالي' : 'Total Price',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.monetization_on_rounded, size: 14, color: AppTheme.accentAmber),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '$formattedTotalPrice $currency',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderSummaryDetailsSheet(BuildContext context, OrderProvider orderProvider) {
    final fabricEntries = orderProvider.fabricEntries;
    final grandTotalRolls = fabricEntries.fold<int>(0, (sum, entry) => sum + entry.sequence.length);

    final totalMeters = fabricEntries
        .where((e) => e.unit == 'meter')
        .fold<double>(0.0, (sum, e) => sum + e.sequence.fold<double>(0.0, (s, val) => s + val));

    final totalKgs = fabricEntries
        .where((e) => e.unit == 'kg')
        .fold<double>(0.0, (sum, e) => sum + e.sequence.fold<double>(0.0, (s, val) => s + val));

    final grandTotalPrice = fabricEntries.fold<double>(
      0.0,
      (sum, entry) {
        final qty = entry.sequence.fold<double>(0.0, (s, val) => s + val);
        return sum + (qty * entry.price);
      },
    );

    final formattedTotalPrice = NumberFormat('#,##0.##', 'en_US').format(grandTotalPrice);
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    final currency = isAr ? 'د.ج' : 'DA';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAr ? 'تفاصيل إجمالي الطلبية' : 'Order Summary Details',
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
                  const Divider(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCol(isAr ? 'الأنواع' : 'Types', '${fabricEntries.where((e) => e.fabricType.isNotEmpty).length}', Icons.texture_rounded),
                        _buildMetricCol(isAr ? 'اللفات' : 'Rolls', '$grandTotalRolls', Icons.layers_rounded),
                        if (totalMeters > 0)
                          _buildMetricCol(isAr ? 'المجموع (م)' : 'Total (m)', '${totalMeters.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} m', Icons.straighten_rounded),
                        if (totalKgs > 0)
                          _buildMetricCol(isAr ? 'المجموع (كغ)' : 'Total (kg)', '${totalKgs.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} kg', Icons.scale_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isAr ? 'تفاصيل كل قماش:' : 'Fabric Breakdown:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: fabricEntries.length,
                      itemBuilder: (context, idx) {
                        final entry = fabricEntries[idx];
                        if (entry.fabricType.isEmpty) return const SizedBox.shrink();

                        final totalQty = entry.sequence.fold(0.0, (sum, val) => sum + val);
                        final totalPrice = totalQty * entry.price;
                        final formattedSubtotal = NumberFormat('#,##0.##', 'en_US').format(totalPrice);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry.fabricType,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${entry.price.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} ${entry.unit == 'kg' ? 'DA/kg' : 'DA/m'}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.accentAmber,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (entry.sequence.isNotEmpty) ...[
                                Text(
                                  '${isAr ? "اللفات" : "Rolls"} (${entry.sequence.length}):',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: (entry.lengths.entries.toList()..sort((a, b) {
                                    final double valA = double.tryParse(a.key) ?? 0.0;
                                    final double valB = double.tryParse(b.key) ?? 0.0;
                                    return valB.compareTo(valA);
                                  })).map((e) {
                                    final displayVal = double.tryParse(e.key);
                                    final displayStr = displayVal != null && displayVal == displayVal.roundToDouble()
                                        ? displayVal.toInt().toString()
                                        : e.key;

                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceElevated,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppTheme.borderSubtle),
                                      ),
                                      child: Text(
                                        e.value > 1 ? '$displayStr ×${e.value}' : displayStr,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${isAr ? "الكمية:" : "Quantity:"} ${totalQty.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} ${entry.unit == 'kg' ? "kg" : "m"}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${isAr ? "المجموع:" : "Subtotal:"} $formattedSubtotal $currency',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.accentAmberLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAr ? 'الإجمالي الكلي:' : 'Grand Total:',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$formattedTotalPrice $currency',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentAmber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCol(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
      ],
    );
  }
}
