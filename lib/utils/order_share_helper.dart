import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';
import 'pdf_invoice_generator.dart';

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
                shareOrderAsImage(context, order);
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

  // ─── Direct Save Image to Device Gallery ────────────────────────────────
  static Future<void> saveOrderImageDirectlyToGallery(BuildContext context, Order order) async {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    final repaintKey = GlobalKey();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) {
        Future.delayed(const Duration(milliseconds: 350), () async {
          try {
            final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
            if (boundary != null) {
              final image = await boundary.toImage(pixelRatio: 3.0);
              final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
              if (byteData != null) {
                final pngBytes = byteData.buffer.asUint8List();
                final shortId = order.id.length > 6 ? order.id.substring(0, 6) : order.id;

                // Save directly to phone's Photo Gallery using Gal
                await Gal.putImageBytes(
                  pngBytes,
                  name: 'TUSSI_Order_$shortId',
                );

                if (dlgCtx.mounted) {
                  Navigator.of(dlgCtx).pop();
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isAr
                                  ? 'تم حفظ صورة الطلبية بنجاح في معرض الصور (Gallery) 🖼️'
                                  : 'Order receipt saved to Photo Gallery! 🖼️',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
                return;
              }
            }
          } catch (e) {
            print('Gal Direct Save Exception: $e');
            // Fallback: write file to external storage Pictures
            try {
              final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
              if (boundary != null) {
                final image = await boundary.toImage(pixelRatio: 3.0);
                final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                if (byteData != null) {
                  final pngBytes = byteData.buffer.asUint8List();
                  final picDir = Directory('/storage/emulated/0/Pictures');
                  if (await picDir.exists()) {
                    final shortId = order.id.length > 6 ? order.id.substring(0, 6) : order.id;
                    final f = File('${picDir.path}/TUSSI_Order_$shortId.png');
                    await f.writeAsBytes(pngBytes);
                  }
                }
              }
            } catch (_) {}
          }

          if (dlgCtx.mounted) {
            Navigator.of(dlgCtx).pop();
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RepaintBoundary(
                  key: repaintKey,
                  child: _buildPrintableReceiptCard(context, order),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── 1. Share Order as Image ─────────────────────────────────────────────
  static Future<void> shareOrderAsImage(BuildContext context, Order order, {bool autoTrigger = false}) async {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    final repaintKey = GlobalKey();

    Future<void> _captureAndShare(BuildContext dlgCtx) async {
      try {
        final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null) return;
        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) return;
        final pngBytes = byteData.buffer.asUint8List();

        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/Order_${order.id.length > 6 ? order.id.substring(0, 6) : order.id}.png');
        await file.writeAsBytes(pngBytes);

        if (context.mounted) {
          Navigator.of(dlgCtx).pop();
        }

        await Share.shareXFiles(
          [XFile(file.path)],
          text: isAr
              ? 'تفاصيل طلبية TUSSI #${order.id.length > 6 ? order.id.substring(0, 6) : order.id}'
              : 'TUSSI Order #${order.id.length > 6 ? order.id.substring(0, 6) : order.id}',
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sharing image: $e')),
          );
        }
      }
    }

    showDialog(
      context: context,
      builder: (dlgCtx) {
        if (autoTrigger) {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (dlgCtx.mounted) {
              _captureAndShare(dlgCtx);
            }
          });
        }

        return Dialog(
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
                    isAr ? 'حفظ / مشاركة الصورة' : 'Save / Share Image',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _captureAndShare(dlgCtx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── 2. Share Order as Document / PDF ───────────────────────────────────
  static Future<void> _shareOrderAsDocument(BuildContext context, Order order) async {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    final shortId = order.id.length > 8 ? order.id.substring(0, 8) : order.id;

    try {
      final file = await PdfInvoiceGenerator.generateOrderPdf(order);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: isAr ? 'مستند فاتورة طلبية TUSSI #$shortId.pdf' : 'TUSSI Order Invoice #$shortId.pdf',
      );
    } catch (e) {
      print('PDF Share Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
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
    final dateFormat = DateFormat('yyyy/MM/dd   HH:mm');
    final priceFormat = NumberFormat('#,##0.##', 'en_US');

    // ── Grand totals ──
    double grandTotal = 0.0;
    int grandCylinders = 0;
    double grandMeters = 0.0;

    for (final f in order.fabrics) {
      final qty = f.sequence.fold(0.0, (s, v) => s + v);
      grandTotal += qty * f.price;
      grandCylinders += f.sequence.length;
      if (f.unit != 'kg') grandMeters += qty;
    }

    const Color _bg       = Color(0xFF16161F);
    const Color _card     = Color(0xFF1E1E2C);
    const Color _divider  = Color(0xFF2E2E3E);
    const Color _gold     = Color(0xFFF5C842);
    const Color _white    = Colors.white;
    final     _muted      = Colors.grey.shade400;

    Widget _row(String label, String value, {Color? valueColor, double fontSize = 11}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: _muted, fontSize: fontSize)),
            Text(value, style: TextStyle(color: valueColor ?? _white, fontSize: fontSize, fontWeight: FontWeight.bold)),
          ],
        ),
      );

    Widget _dividerWidget() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(height: 1, color: _divider),
    );

    return Container(
      width: 340,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold, width: 1.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ──────────────────────────────────────
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront_rounded, color: _gold, size: 32),
                ),
                const SizedBox(height: 8),
                const Text(
                  'TUSSI SYSTEM',
                  style: TextStyle(color: _white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2.5),
                ),
                const SizedBox(height: 2),
                Text(
                  'فاتورة طلبية أقمشة',
                  style: TextStyle(color: _gold, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          _dividerWidget(),

          // ── Order Info ───────────────────────────────────
          _row('رقم الطلب:', '#${order.id.length > 10 ? order.id.substring(0, 10) : order.id}'),
          _row('التاريخ:', dateFormat.format(order.createdAt)),
          _row('المرسل (المحل):', order.senderName, valueColor: _gold),
          _row('المستلم:', order.receiverName),
          if (order.customerName != null && order.customerName!.isNotEmpty)
            _row('الزبون:', order.customerName!, valueColor: _gold, fontSize: 13),

          _dividerWidget(),

          // ── Fabrics count badge ──────────────────────────
          Row(
            children: [
              const Icon(Icons.texture_rounded, color: _gold, size: 14),
              const SizedBox(width: 6),
              Text(
                'الأقمشة (${order.fabrics.length} نوع)',
                style: const TextStyle(color: _white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Per-fabric details ───────────────────────────
          ...order.fabrics.asMap().entries.map((entry) {
            final idx = entry.key;
            final f = entry.value;
            final qty = f.sequence.fold(0.0, (s, v) => s + v);
            final fabricTotal = qty * f.price;
            final unitText = f.unit == 'kg' ? 'كغ' : (f.unit == 'yard' ? 'يارد' : 'متر');

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fabric name
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(color: _gold, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f.fabricType,
                            style: const TextStyle(color: _white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Stats row
                    Row(
                      children: [
                        // Cylinders
                        Expanded(
                          child: Column(
                            children: [
                              Text('الأسطوانات', style: TextStyle(color: _muted, fontSize: 9)),
                              const SizedBox(height: 3),
                              Text('${f.sequence.length}', style: const TextStyle(color: _white, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 28, color: _divider),
                        // Meters / qty
                        Expanded(
                          child: Column(
                            children: [
                              Text('الكمية', style: TextStyle(color: _muted, fontSize: 9)),
                              const SizedBox(height: 3),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${qty.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} $unitText',
                                  style: const TextStyle(color: _white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 28, color: _divider),
                        // Unit price
                        Expanded(
                          child: Column(
                            children: [
                              Text('السعر/$unitText', style: TextStyle(color: _muted, fontSize: 9)),
                              const SizedBox(height: 3),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${priceFormat.format(f.price)} د.ج',
                                  style: const TextStyle(color: _white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 28, color: _divider),
                        // Fabric total
                        Expanded(
                          child: Column(
                            children: [
                              Text('الإجمالي', style: TextStyle(color: _muted, fontSize: 9)),
                              const SizedBox(height: 3),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${priceFormat.format(fabricTotal)} د.ج',
                                  style: const TextStyle(color: _gold, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          _dividerWidget(),

          // ── Grand summary ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _gold.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('إجمالي الأقمشة:', style: TextStyle(color: _muted, fontSize: 11)),
                    Text('${order.fabrics.length} نوع', style: const TextStyle(color: _white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('إجمالي الأسطوانات:', style: TextStyle(color: _muted, fontSize: 11)),
                    Text('$grandCylinders اسطوانة', style: const TextStyle(color: _white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                if (grandMeters > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('إجمالي المتر:', style: TextStyle(color: _muted, fontSize: 11)),
                      Text('${grandMeters.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} م', style: const TextStyle(color: _white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Container(height: 1, color: _gold.withValues(alpha: 0.3)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إجمالي الطلبية:', style: TextStyle(color: _white, fontSize: 14, fontWeight: FontWeight.bold)),
                    Text(
                      '${priceFormat.format(grandTotal)} د.ج',
                      style: const TextStyle(color: _gold, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          // ── Footer ──────────────────────────────────────
          Center(
            child: Text(
              'tussi.web.app • نظام توسي للأقمشة',
              style: TextStyle(color: _muted, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
