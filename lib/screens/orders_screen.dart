import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/language_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/order_card.dart';
import '../providers/order_provider.dart';
import '../utils/order_share_helper.dart';
import '../widgets/ai_assistant_dialog.dart';
import 'home_screen.dart';
import 'payments_screen.dart';

/// Screen showing pending orders assigned to (Inbox) or sent by (Sent) the current user.
/// Supports real-time updates, tab switching, completions, and recall/editing.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';

  void _showQRScanDialog(BuildContext context) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    final MobileScannerController scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    bool _scanned = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppTheme.accentAmber,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'مسح رمز QR للطلبية' : 'Scan Order QR Code',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isAr
                                ? 'وجّه الكاميرا نحو رمز QR للطلبية'
                                : 'Point the camera at the order QR code',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: AppTheme.textMuted),
                      onPressed: () {
                        scannerController.dispose();
                        Navigator.of(sheetCtx).pop();
                      },
                    ),
                  ],
                ),
              ),
              // Camera view
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Camera feed
                        MobileScanner(
                          controller: scannerController,
                          onDetect: (capture) async {
                            if (_scanned) return;
                            final barcode = capture.barcodes.firstOrNull;
                            final rawValue = barcode?.rawValue;
                            if (rawValue != null && rawValue.isNotEmpty) {
                              _scanned = true;
                              scannerController.dispose();
                              Navigator.of(sheetCtx).pop();

                              final cleanCode = rawValue.trim();
                              setState(() => _searchQuery = cleanCode);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          isAr
                                              ? 'جاري جلب الفاتورة وتوليد صورة الطلبية... 🖼️'
                                              : 'Fetching order & generating image... 🖼️',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppTheme.accentAmber,
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );

                              // Fetch order by ID & automatically save receipt image to phone gallery
                              final scannedOrder = await FirestoreService().getOrderById(cleanCode);
                              if (scannedOrder != null && context.mounted) {
                                OrderShareHelper.saveOrderImageDirectlyToGallery(context, scannedOrder);
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isAr
                                          ? 'تم تصفية الطلبيات برقم الكود: $cleanCode 🔍'
                                          : 'Filtered by QR Code: $cleanCode 🔍',
                                    ),
                                    backgroundColor: AppTheme.accentAmber.withValues(alpha: 0.9),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    margin: const EdgeInsets.all(16),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        // Scan frame overlay
                        IgnorePointer(
                          child: CustomPaint(
                            painter: _QRScanFramePainter(
                                color: AppTheme.accentAmber),
                            child: const SizedBox(
                              width: 220,
                              height: 220,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Torch toggle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: StatefulBuilder(
                  builder: (ctx, setBtn) {
                    bool torchOn = false;
                    return TextButton.icon(
                      onPressed: () async {
                        await scannerController.toggleTorch();
                        setBtn(() => torchOn = !torchOn);
                      },
                      icon: Icon(
                        torchOn
                            ? Icons.flashlight_on_rounded
                            : Icons.flashlight_off_rounded,
                        color: torchOn
                            ? AppTheme.accentAmber
                            : AppTheme.textMuted,
                      ),
                      label: Text(
                        isAr ? 'تشغيل/إيقاف الفلاش' : 'Toggle Flash',
                        style: TextStyle(
                          color: torchOn
                              ? AppTheme.accentAmber
                              : AppTheme.textMuted,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      // Safely dispose controller when sheet is dismissed by any means
      try {
        scannerController.dispose();
      } catch (_) {}
    });
  }

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
      length: 3,
      child: Column(
        children: [
          // ─── Search & QR Scanner Header ────────────────────────
          Container(
            color: AppTheme.surfaceDark,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: isAr ? 'بحث برقم الطلبية أو الزبون...' : 'Search Order ID or Customer...',
                        hintStyle: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.qr_code_scanner_rounded, color: AppTheme.accentAmber),
                  tooltip: isAr ? 'مسح رمز QR للطلبية' : 'Scan Order QR',
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.accentAmber.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showQRScanDialog(context),
                ),
              ],
            ),
          ),

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
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(text: isAr ? 'الواردة' : 'Received'),
                  Tab(text: isAr ? 'المرسلة' : 'Sent'),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded, size: 14),
                        const SizedBox(width: 4),
                        Text(isAr ? 'الذمم' : 'Debts'),
                      ],
                    ),
                  ),
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
                // 3. Debts Tab (الذمم)
                const PaymentsScreen(),
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

        var orders = snapshot.data ?? [];
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          orders = orders.where((o) =>
            o.id.toLowerCase().contains(q) ||
            o.senderName.toLowerCase().contains(q) ||
            o.receiverName.toLowerCase().contains(q) ||
            (o.customerName != null && o.customerName!.toLowerCase().contains(q))
          ).toList();
        }

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

/// Custom painter that draws QR scan corner brackets
class _QRScanFramePainter extends CustomPainter {
  final Color color;
  _QRScanFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double cornerLen = 30.0;
    const double r = 8.0;
    final w = size.width;
    final h = size.height;

    // Top-left
    canvas.drawLine(Offset(r, 0), Offset(cornerLen, 0), paint);
    canvas.drawLine(Offset(0, r), Offset(0, cornerLen), paint);
    canvas.drawArc(
        Rect.fromLTWH(0, 0, r * 2, r * 2), 3.14159, -1.5708, false, paint);

    // Top-right
    canvas.drawLine(Offset(w - cornerLen, 0), Offset(w - r, 0), paint);
    canvas.drawLine(Offset(w, r), Offset(w, cornerLen), paint);
    canvas.drawArc(
        Rect.fromLTWH(w - r * 2, 0, r * 2, r * 2), 1.5708, -1.5708, false, paint);

    // Bottom-left
    canvas.drawLine(Offset(0, h - cornerLen), Offset(0, h - r), paint);
    canvas.drawLine(Offset(r, h), Offset(cornerLen, h), paint);
    canvas.drawArc(
        Rect.fromLTWH(0, h - r * 2, r * 2, r * 2), 1.5708, 1.5708, false, paint);

    // Bottom-right
    canvas.drawLine(Offset(w, h - cornerLen), Offset(w, h - r), paint);
    canvas.drawLine(Offset(w - cornerLen, h), Offset(w - r, h), paint);
    canvas.drawArc(
        Rect.fromLTWH(w - r * 2, h - r * 2, r * 2, r * 2), 0, 1.5708, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
