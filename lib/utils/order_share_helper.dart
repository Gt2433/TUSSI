import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';

class OrderShareHelper {
  // ─── Main Share Options Dialog ──────────────────────────────────────────
  static void showShareModal(BuildContext context, Order order) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomCtx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.share_rounded, color: AppTheme.accentAmber, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'مشاركة وتصدير الطلبية' : 'Share & Export Order',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '#${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Option 1: Share as High Quality Image
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.image_rounded, color: Colors.blue),
              ),
              title: Text(
                isAr ? '🖼️ مشاركة / تحميل كصورة' : '🖼️ Share / Download as Image',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                isAr ? 'إنشاء صورة فاتورة كاملة ومشاركتها' : 'Generate full invoice image and share',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              onTap: () {
                Navigator.of(bottomCtx).pop();
                _shareOrderAsImage(context, order);
              },
            ),
            const Divider(),

            // Option 2: Share as PDF / Document
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
              ),
              title: Text(
                isAr ? '📄 مشاركة / تحميل كملف PDF' : '📄 Share / Download as PDF',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                isAr ? 'تصدير مستند تفصيلي كـ PDF / HTML' : 'Export detailed document as PDF / HTML',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              onTap: () {
                Navigator.of(bottomCtx).pop();
                _shareOrderAsDocument(context, order);
              },
            ),
            const Divider(),

            // Option 3: Order QR Code
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.qr_code_2_rounded, color: AppTheme.accentAmber),
              ),
              title: Text(
                isAr ? '📲 عرض رمز QR للطلبية' : '📲 Show Order QR Code',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                isAr ? 'رمز QR سريع لمسح الطلبية والتعرف عليها' : 'Quick QR Code for scanning and lookup',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              onTap: () {
                Navigator.of(bottomCtx).pop();
                showOrderQRModal(context, order);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── 1. Share Order as Image ─────────────────────────────────────────────
  static Future<void> _shareOrderAsImage(BuildContext context, Order order) async {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    final repaintKey = GlobalKey();

    showDialog(
      context: context,
      builder: (dlgCtx) => Dialog(
        backgroundColor: Colors.transparent,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                key: repaintKey,
                child: _buildPrintableReceiptCard(context, order),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentAmber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.share_rounded),
                label: Text(
                  isAr ? 'مشاركة الصورة الآن' : 'Share Image Now',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  try {
                    final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
                    if (boundary == null) return;
                    final image = await boundary.toImage(pixelRatio: 3.0);
                    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                    if (byteData == null) return;
                    final pngBytes = byteData.buffer.asUint8List();

                    final tempDir = Directory.systemTemp;
                    final file = File('${tempDir.path}/Order_${order.id.substring(0, 6)}.png');
                    await file.writeAsBytes(pngBytes);

                    if (context.mounted) {
                      Navigator.of(dlgCtx).pop();
                    }

                    await Share.shareXFiles(
                      [XFile(file.path)],
                      text: isAr ? 'تفاصيل طلبية TUSSI #${order.id.substring(0, 6)}' : 'TUSSI Order #${order.id.substring(0, 6)}',
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error sharing image: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 2. Share Order as Document / PDF ───────────────────────────────────
  static Future<void> _shareOrderAsDocument(BuildContext context, Order order) async {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final formattedPrice = NumberFormat('#,##0.##', 'en_US').format(order.computedTotal);
    final paidPrice = NumberFormat('#,##0.##', 'en_US').format(order.paidAmount ?? 0);
    final balancePrice = NumberFormat('#,##0.##', 'en_US').format(order.balanceDue);

    StringBuffer sb = StringBuffer();
    sb.writeln('========================================');
    sb.writeln('          TUSSI FABRIC SYSTEM           ');
    sb.writeln('            فاتورة طلبية أقمشة          ');
    sb.writeln('========================================');
    sb.writeln('رقم الطلب (Order ID): #${order.id}');
    sb.writeln('التاريخ (Date): ${dateFormat.format(order.createdAt)}');
    sb.writeln('المرسل (From): ${order.senderName}');
    sb.writeln('المستلم (To): ${order.receiverName}');
    if (order.customerName != null && order.customerName!.isNotEmpty) {
      sb.writeln('الزبون (Customer): ${order.customerName}');
    }
    sb.writeln('----------------------------------------');
    sb.writeln('الأقمشة المطلوبة (Fabrics List):');

    for (var i = 0; i < order.fabrics.length; i++) {
      final f = order.fabrics[i];
      final qty = f.sequence.fold(0.0, (s, v) => s + v);
      sb.writeln('${i + 1}. ${f.fabricType}');
      sb.writeln('   عدد الأسطوانات: ${f.sequence.length} | الكمية: $qty ${f.unit}');
      sb.writeln('   الأطوال التفصيلية: [${f.sequence.join(', ')}]');
      sb.writeln('   السعر: ${NumberFormat('#,##0.##', 'en_US').format(qty * f.price)} د.ج');
      sb.writeln('');
    }

    sb.writeln('----------------------------------------');
    sb.writeln('إجمالي السعر (Total): $formattedPrice د.ج');
    sb.writeln('المبلغ المدفوع (Paid): $paidPrice د.ج');
    sb.writeln('المبلغ المتبقي (Balance): $balancePrice د.ج');
    sb.writeln('حالة الدفع (Status): ${order.paymentStatus}');
    sb.writeln('========================================');
    sb.writeln('tussi.web.app - TUSSI App');

    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/Order_${order.id.substring(0, 6)}.txt');
    await file.writeAsString(sb.toString(), encoding: utf8);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: isAr ? 'ملف فاتورة طلبية TUSSI' : 'TUSSI Order Document',
    );
  }

  // ─── 3. Show Order QR Code Modal ─────────────────────────────────────────
  static void showOrderQRModal(BuildContext context, Order order) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    final qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${Uri.encodeComponent(order.id)}';

    showDialog(
      context: context,
      builder: (dlgCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppTheme.surfaceCard,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentAmber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.qr_code_2_rounded, color: AppTheme.accentAmber, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                isAr ? 'رمز QR الخاص بالطلبية' : 'Order QR Code',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '#${order.id.length > 10 ? order.id.substring(0, 10) : order.id}',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),

              // QR Code Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.network(
                  qrUrl,
                  width: 180,
                  height: 180,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: 180, height: 180,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 180, height: 180,
                    color: AppTheme.surfaceDark,
                    child: const Icon(Icons.qr_code_2_rounded, size: 64, color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.accentAmber),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text(isAr ? 'نسخ الكود' : 'Copy ID', style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: order.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isAr ? 'تم نسخ كود الطلبية 📋' : 'Order ID copied 📋')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentAmber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: Text(isAr ? 'مشاركة QR' : 'Share QR', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        Navigator.of(dlgCtx).pop();
                        final text = 'رمز طلبية TUSSI #${order.id.substring(0, 6)}:\n$qrUrl';
                        await Share.share(text);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(dlgCtx).pop(),
                child: Text(isAr ? 'إغلاق' : 'Close', style: TextStyle(color: AppTheme.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Printable Receipt Layout Widget ────────────────────────────────────
  static Widget _buildPrintableReceiptCard(BuildContext context, Order order) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final formattedPrice = NumberFormat('#,##0.##', 'en_US').format(order.computedTotal);

    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentAmber, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Icon(Icons.storefront_rounded, color: AppTheme.accentAmber, size: 36),
                const SizedBox(height: 4),
                const Text(
                  'TUSSI SYSTEM',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
                Text(
                  'فاتورة طلبية أقمشة',
                  style: TextStyle(color: AppTheme.accentAmber, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('رقم الطلب:', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
              Text('#${order.id.substring(0, 8)}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('التاريخ:', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
              Text(dateFormat.format(order.createdAt), style: const TextStyle(color: Colors.white, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('من -> إلى:', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
              Text('${order.senderName} ➔ ${order.receiverName}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          if (order.customerName != null && order.customerName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الزبون:', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                Text(order.customerName!, style: TextStyle(color: AppTheme.accentAmber, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          const Text('تفاصيل الأقمشة:', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          ...order.fabrics.map((f) {
            final qty = f.sequence.fold(0.0, (s, v) => s + v);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        f.fabricType,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '${f.sequence.length} اسطوانة | $qty ${f.unit}',
                      style: TextStyle(color: AppTheme.accentAmber, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إجمالي السعر:', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              Text('$formattedPrice د.ج', style: TextStyle(color: AppTheme.accentAmber, fontSize: 16, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}
