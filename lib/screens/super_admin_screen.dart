import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final _shopNameController = TextEditingController();
  final _yearsController = TextEditingController(text: '0');
  final _daysController = TextEditingController(text: '0');
  final _hoursController = TextEditingController(text: '0');
  final _minutesController = TextEditingController(text: '0');
  final _secondsController = TextEditingController(text: '0');
  final _formKey = GlobalKey<FormState>();
  bool _isGenerating = false;
  late TabController _tabController;
  Timer? _statusUpdateTimer;
  Stream<List<Map<String, dynamic>>>? _shopsStream;
  Stream<List<Map<String, dynamic>>>? _codesStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _shopsStream = _firestoreService.streamAllShops();
    _codesStream = _firestoreService.streamAllActivationCodes();
    // Periodically rebuild screen to show expired status in real-time
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _statusUpdateTimer?.cancel();
    _shopNameController.dispose();
    _yearsController.dispose();
    _daysController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ─── Generate Activation Code ──────────────────────────────────
  Future<void> _generateCode() async {
    if (!_formKey.currentState!.validate()) return;

    final shopName = _shopNameController.text.trim();
    final int years = int.tryParse(_yearsController.text) ?? 0;
    final int days = int.tryParse(_daysController.text) ?? 0;
    final int hours = int.tryParse(_hoursController.text) ?? 0;
    final int minutes = int.tryParse(_minutesController.text) ?? 0;
    final int seconds = int.tryParse(_secondsController.text) ?? 0;

    final int totalSeconds = (years * 365 * 24 * 60 * 60) +
                             (days * 24 * 60 * 60) +
                             (hours * 60 * 60) +
                             (minutes * 60) +
                             seconds;

    if (totalSeconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد مدة اشتراك صالحة (أكثر من 0 ثانية).'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);
    try {
      final code = await _firestoreService.generateActivationCode(shopName, totalSeconds);
      _shopNameController.clear();
      _yearsController.text = '0';
      _daysController.text = '0';
      _hoursController.text = '0';
      _minutesController.text = '0';
      _secondsController.text = '0';

      if (mounted) {
        _showSuccessDialog(code, shopName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء توليد الكود: $e'),
            backgroundColor: AppTheme.errorSurface,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  // ─── Share via WhatsApp ────────────────────────────────────────
  Future<void> _shareToWhatsApp(String code, String shopName) async {
    final message =
        'مرحباً يا صاحب محل $shopName، كود التفعيل الخاص بك لتطبيق Fantex هو:\n\n👉 *$code*\n\nيرجى فتح التطبيق، النقر على "إنشاء حساب" ثم إدخال اسمك، إيميلك، وكلمة سر مع هذا الكود.';
    final encodedMessage = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/?text=$encodedMessage');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ─── Success Dialog ───────────────────────────────────────────
  void _showSuccessDialog(String code, String shopName) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppTheme.surfaceCard,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.accentAmber.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.vpn_key_rounded,
                  color: AppTheme.accentAmber,
                  size: 42,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'تم توليد الكود بنجاح!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'محل: $shopName',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      code,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: AppTheme.accentAmber,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.copy_rounded, color: AppTheme.textSecondary, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('تم نسخ كود التفعيل إلى الحافظة!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text(
                    'مشاركة عبر واتساب',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _shareToWhatsApp(code, shopName);
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'إغلاق',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المشرف العام'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentAmber,
          labelColor: AppTheme.accentAmber,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'توليد الأكواد'),
            Tab(text: 'المحلات المشتركة'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.surfaceGradient),
        child: TabBarView(
          controller: _tabController,
          children: [
            // TAB 1: CODE GENERATION
            _buildCodeGenerationTab(),

            // TAB 2: REGISTERED SHOPS
            _buildShopsTab(),
          ],
        ),
      ),
    );
  }

  // ─── Tab 1: Code Generation & History ──────────────────────────
  Widget _buildCodeGenerationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Generation form
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'توليد كود تفعيل لمحل جديد',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _shopNameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المحل المشترك',
                      hintText: 'مثال: محلات النور الفاخرة',
                      prefixIcon: Icon(Icons.store_rounded),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'يرجى إدخال اسم المحل لتسجيله';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'مدة صلاحية كود التفعيل:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _yearsController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            labelText: 'سنة',
                            contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextFormField(
                          controller: _daysController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            labelText: 'يوم',
                            contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextFormField(
                          controller: _hoursController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            labelText: 'ساعة',
                            contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextFormField(
                          controller: _minutesController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            labelText: 'دقيقة',
                            contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextFormField(
                          controller: _secondsController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            labelText: 'ثانية',
                            contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateCode,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.add_moderator_rounded),
                      label: Text(_isGenerating ? 'جاري توليد الكود...' : 'إنشاء كود تفعيل جديد'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentAmber,
                        foregroundColor: AppTheme.surfaceDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Generated codes list title
          const Text(
            'أكواد التفعيل الصادرة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // Stream of all codes
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _codesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ));
              }

              final codes = snapshot.data ?? [];
              if (codes.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'لا توجد أكواد تفعيل حالياً.',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                );
              }

              // Sort newest first
              codes.sort((a, b) {
                final aTime = a['createdAt'] as Timestamp?;
                final bTime = b['createdAt'] as Timestamp?;
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime);
              });

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: codes.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final item = codes[idx];
                  final code = item['code'] as String;
                  final shopName = item['shopName'] as String? ?? 'محل غير معروف';
                  final isUsed = item['isUsed'] as bool? ?? false;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUsed
                            ? AppTheme.borderSubtle
                            : AppTheme.accentAmber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Status indicator
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isUsed
                                ? AppTheme.textMuted.withValues(alpha: 0.1)
                                : AppTheme.accentAmber.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isUsed ? Icons.check_circle_outline_rounded : Icons.vpn_key_rounded,
                            color: isUsed ? AppTheme.textMuted : AppTheme.accentAmber,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Shop info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                code,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                shopName,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Action button or usage indicator
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isUsed)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceElevated,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'مُستخدَم',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.share_rounded, color: Color(0xFF25D366)),
                                onPressed: () => _shareToWhatsApp(code, shopName),
                                tooltip: 'مشاركة الكود',
                              ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 22),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('حذف كود التفعيل'),
                                    content: Text('هل أنت متأكد من حذف كود التفعيل "$code" لمحل "$shopName"؟'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(false),
                                        child: const Text('إلغاء'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(ctx).pop(true),
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                        child: const Text('حذف'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _firestoreService.deleteActivationCode(code);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('تم حذف كود التفعيل بنجاح.')),
                                    );
                                  }
                                }
                              },
                              tooltip: 'حذف الكود',
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Tab 2: Shops List ──────────────────────────────────────────
  Widget _buildShopsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _shopsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final shops = snapshot.data ?? [];
        if (shops.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'لا توجد محلات مسجلة حالياً.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: shops.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, idx) {
            final shop = shops[idx];
            final shopName = shop['name'] as String? ?? 'محل بدون اسم';
            final inviteCode = shop['inviteCode'] as String? ?? 'لا يوجد';
            final shopId = shop['id'] as String? ?? '';
            final bool isActive = shop['isActive'] as bool? ?? true;
            final Timestamp? expiryTimestamp = shop['subscriptionExpiresAt'] as Timestamp?;

            String expiryStr = 'لا يوجد تاريخ';
            bool isExpired = false;
            if (expiryTimestamp != null) {
              final date = expiryTimestamp.toDate();
              expiryStr = '${date.day}/${date.month}/${date.year}';
              isExpired = date.isBefore(DateTime.now());
            }

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: !isActive || isExpired
                      ? Colors.redAccent.withValues(alpha: 0.3)
                      : AppTheme.borderSubtle,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: !isActive || isExpired
                              ? Colors.redAccent.withValues(alpha: 0.1)
                              : AppTheme.accentAmber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.store_rounded,
                          color: !isActive || isExpired ? Colors.redAccent : AppTheme.accentAmber,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shopName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              !isActive
                                  ? 'الحالة: معطّل مؤقتاً'
                                  : isExpired
                                      ? 'الحالة: منتهي الاشتراك'
                                      : 'الحالة: نشط',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: !isActive || isExpired ? Colors.redAccent : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Invite Code Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'كود دعوة الموظفين:',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              inviteCode,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentAmber,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: inviteCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم نسخ كود دعوة الموظفين!'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: Icon(Icons.copy_rounded, size: 14, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Expiry Date Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'انتهاء الاشتراك:',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        expiryStr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isExpired ? Colors.redAccent : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showExtendSubscriptionDialog(context, shop),
                          icon: const Icon(Icons.history_toggle_off_rounded, size: 16),
                          label: const Text('تعديل الاشتراك / تمديد', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentAmber,
                            foregroundColor: AppTheme.surfaceDark,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await _firestoreService.updateShopSubscription(
                            shopId,
                            expiryTimestamp?.toDate() ?? DateTime.now().add(const Duration(days: 30)),
                            !isActive,
                          );
                          _showSuccessSnackbar(isActive ? 'تم تعطيل المحل بنجاح' : 'تم تفعيل المحل بنجاح');
                        },
                        icon: Icon(isActive ? Icons.block_rounded : Icons.check_circle_rounded, size: 16),
                        label: Text(isActive ? 'تعطيل' : 'تفعيل', style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isActive ? Colors.redAccent : Colors.green,
                          side: BorderSide(color: isActive ? Colors.redAccent : Colors.green),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _deleteShop(shopId, shopName),
                        icon: Icon(Icons.delete_forever_rounded, color: AppTheme.error, size: 24),
                        tooltip: 'حذف المحل نهائياً',
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Extend Subscription Dialog ─────────────────────────────────
  void _showExtendSubscriptionDialog(BuildContext context, Map<String, dynamic> shop) {
    final shopId = shop['id'] as String;
    final shopName = shop['name'] as String? ?? 'محل';
    final bool currentActive = shop['isActive'] as bool? ?? true;
    final Timestamp? currentExpiry = shop['subscriptionExpiresAt'] as Timestamp?;
    final extYears = TextEditingController(text: '0');
    final extDays = TextEditingController(text: '0');
    final extHours = TextEditingController(text: '0');
    final extMinutes = TextEditingController(text: '0');
    final extSeconds = TextEditingController(text: '0');

    bool startFromNow = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          DateTime baseDate = DateTime.now();
          if (!startFromNow && currentExpiry != null) {
            final expiryDate = currentExpiry.toDate();
            if (expiryDate.isAfter(DateTime.now())) {
              baseDate = expiryDate;
            }
          }
          return AlertDialog(
            backgroundColor: AppTheme.surfaceCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text('تعديل اشتراك $shopName'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تمديد الاشتراك بالمدة المحددة:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: extYears,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            labelText: 'سنة',
                            contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextFormField(
                          controller: extDays,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            labelText: 'يوم',
                            contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextFormField(
                          controller: extHours,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            labelText: 'ساعة',
                            contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextFormField(
                          controller: extMinutes,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            labelText: 'دقيقة',
                            contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextFormField(
                          controller: extSeconds,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            labelText: 'ثانية',
                            contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'إعادة ضبط الاشتراك',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'بدء الاحتساب من الوقت الحالي للتعويض',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      Switch(
                        value: startFromNow,
                        activeColor: AppTheme.accentAmber,
                        onChanged: (val) {
                          setDialogState(() {
                            startFromNow = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.calendar_month_rounded, color: AppTheme.accentAmber),
                    title: const Text('أو حدد تاريخ انتهاء مخصص', style: TextStyle(fontSize: 14)),
                    onTap: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: baseDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (selectedDate != null) {
                        Navigator.of(ctx).pop();
                        await _firestoreService.updateShopSubscription(shopId, selectedDate, currentActive);
                        _showSuccessSnackbar('تم تعديل الاشتراك لـ $shopName بنجاح.');
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final int years = int.tryParse(extYears.text) ?? 0;
                  final int days = int.tryParse(extDays.text) ?? 0;
                  final int hours = int.tryParse(extHours.text) ?? 0;
                  final int minutes = int.tryParse(extMinutes.text) ?? 0;
                  final int seconds = int.tryParse(extSeconds.text) ?? 0;

                  final int totalSeconds = (years * 365 * 24 * 60 * 60) +
                                           (days * 24 * 60 * 60) +
                                           (hours * 60 * 60) +
                                           (minutes * 60) +
                                           seconds;

                  if (totalSeconds <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('يرجى إدخال مدة تمديد صالحة.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  Navigator.of(ctx).pop();
                  final newExpiry = baseDate.add(Duration(seconds: totalSeconds));
                  await _firestoreService.updateShopSubscription(shopId, newExpiry, currentActive);
                  _showSuccessSnackbar('تم تمديد الاشتراك لـ $shopName بنجاح.');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentAmber,
                  foregroundColor: AppTheme.surfaceDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('تمديد الآن'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Delete Shop permanently ──────────────────────────────────────
  Future<void> _deleteShop(String shopId, String shopName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('حذف المحل نهائياً'),
        content: Text('هل أنت متأكد من حذف المحل "$shopName" نهائياً؟ \nسيتم إلغاء تفعيل كافة الأكواد والحسابات المرتبطة به ولن يتمكن أي مستخدم من الدخول إليه بعد الآن.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestoreService.deleteShop(shopId);
      if (mounted) {
        _showSuccessSnackbar('تم حذف المحل "$shopName" نهائياً بنجاح.');
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
