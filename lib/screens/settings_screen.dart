import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import 'help_guide_screen.dart';
import '../services/update_service.dart';
import '../widgets/download_progress_dialog.dart';

class SettingsScreen extends StatelessWidget {
  final bool isTab;
  const SettingsScreen({super.key, this.isTab = false});

  static const String _kCurrentVersion = '4.0.0';
  static const String currentVersion = _kCurrentVersion;

  // ─── Glassmorphism Helpers ─────────────────────────────────────
  static Widget _buildGlassDialog({
    required BuildContext context,
    required Widget child,
    double maxWidth = 420,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24),
    double borderRadius = 28,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF131722) : Colors.white)
                      .withOpacity(isDark ? 0.84 : 0.92),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.14)
                        : Colors.black.withOpacity(0.08),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 32,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildGlassBottomSheet({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry? padding,
    double borderRadius = 30,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF131722) : Colors.white)
                .withOpacity(isDark ? 0.86 : 0.94),
            borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.14)
                  : Colors.black.withOpacity(0.08),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 28,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.accentAmber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.accentAmber),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentAmber,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry? margin,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: child,
      ),
    );
  }

  Widget _buildHeroShopCard({
    required BuildContext context,
    required FirestoreService firestoreService,
    required String shopId,
    required bool isAr,
    required String? userRole,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roleName = userRole == 'shop_admin'
        ? (isAr ? 'مدير المحل' : 'Shop Admin')
        : (isAr ? 'عضو في المحل' : 'Shop Member');

    return StreamBuilder<Map<String, dynamic>?>(
      stream: firestoreService.streamShopDetails(shopId),
      builder: (context, snapshot) {
        final shopData = snapshot.data;
        final shopName = shopData?['name'] as String? ?? (isAr ? 'المحل' : 'My Shop');
        final rawCode = (shopData?['shopCode'] as String?)?.isNotEmpty == true
            ? shopData!['shopCode'] as String
            : ((shopData?['inviteCode'] as String?)?.isNotEmpty == true
                ? shopData!['inviteCode'] as String
                : null);

        if (rawCode == null && shopData != null && shopId.isNotEmpty) {
          firestoreService.ensureShopCode(shopId, shopName, inviteCode: shopData['inviteCode'] as String?);
        }
        final shopCode = rawCode ?? '...';

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.accentAmber.withOpacity(isDark ? 0.16 : 0.10),
                AppTheme.surfaceCard,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppTheme.accentAmber.withOpacity(0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentAmber.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Shop icon + name + role badge
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.accentAmber,
                            AppTheme.accentAmberDark,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentAmber.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Colors.black,
                        size: 28,
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
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentAmber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              roleName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentAmber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),
                // Code Row with Copy & Quick buttons
                Text(
                  isAr ? 'كود الانضمام للمحل (دعوة العمال):' : 'Shop Join Code (Invite Workers):',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: shopCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isAr ? 'تم نسخ كود المحل بنجاح ✓' : 'Shop code copied ✓'),
                              backgroundColor: AppTheme.successSurface,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.accentAmber.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                shopCode,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: AppTheme.accentAmber,
                                ),
                              ),
                              Icon(Icons.copy_rounded, size: 18, color: AppTheme.accentAmber),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => _showShopQRCodeModal(context, shopName, shopCode),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentAmber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.qr_code_rounded, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            isAr ? 'مشاركة' : 'Share',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
      },
    );
  }

  // ─── Show "About App" Dialog ──────────────────────────────────
  void _showAboutDialog(BuildContext context) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    
    showDialog(
      context: context,
      builder: (ctx) => _buildGlassDialog(
        context: ctx,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo/Icon Container
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceDark,
                border: Border.all(
                  color: AppTheme.borderSubtle,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Transform.scale(
                  scale: 1.45,
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.store_rounded,
                      size: 48,
                      color: AppTheme.accentAmber,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // App Name
            ShaderMask(
              shaderCallback: (bounds) => AppTheme.accentGradient.createShader(bounds),
              child: const Text(
                'TUSSI',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isAr ? 'نظام إدارة الأقمشة والطلبيات' : 'Fabric & Order Management System',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 14),

            // MBD Tagline Quote & Logo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accentAmber.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/MBD.png',
                      height: 30,
                      width: 30,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.workspace_premium_rounded,
                        color: AppTheme.accentAmber,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isAr ? '« من مشاريع MBD »' : '« From MBD Projects »',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentAmber,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            // Creator & Info
            Text(
              isAr ? 'المطور وبرمجة التطبيق' : 'Developer & Creator',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'MOHAMMED BAHAYOU',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isAr ? 'الإصدار الحالي: $_kCurrentVersion' : 'Version: $_kCurrentVersion',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentAmber,
                  foregroundColor: AppTheme.surfaceDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.send_rounded),
                label: Text(
                  isAr ? 'تواصل مع المطور' : 'Contact Developer',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final url = Uri.parse('https://wa.me/213655603829');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                isAr ? 'إغلاق' : 'Close',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Show "Share App" Dialog ──────────────────────────────────
  void _showShareAppDialog(BuildContext context) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    
    showDialog(
      context: context,
      builder: (dialogCtx) => _buildGlassDialog(
        context: dialogCtx,
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('app_updates').doc('latest').get(),
          builder: (context, snapshot) {
            String apkUrl = 'https://tussi.web.app';
            if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              apkUrl = data?['url'] as String? ?? apkUrl;
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.share_rounded, color: AppTheme.accentAmber, size: 24),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isAr ? 'مشاركة ونشر التطبيق' : 'Share Application',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isAr 
                      ? 'انقر على الزر أدناه لمشاركة رابط تحميل التطبيق مباشرة:'
                      : 'Click below to share the application download link directly:',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentAmber,
                      foregroundColor: AppTheme.surfaceDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.share_rounded),
                    label: Text(
                      isAr ? 'مشاركة رابط التحميل' : 'Share Download Link',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      Navigator.of(dialogCtx).pop();
                      final message = isAr 
                          ? 'السلام عليكم، يمكنك تحميل تطبيق TUSSI لإدارة الأقمشة مباشرة من الرابط التالي:\n$apkUrl'
                          : 'Hello, you can download the TUSSI Fabric Management app directly from this link:\n$apkUrl';
                      await SharePlus.instance.share(
                        ShareParams(
                          text: message,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(
                    isAr ? 'إغلاق' : 'Close',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Show Shop QR Code & Join Code Modal ──────────────────────
  void _showShopQRCodeModal(BuildContext context, String shopName, String shopCode) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';

    showDialog(
      context: context,
      builder: (dialogCtx) => _buildGlassDialog(
        context: dialogCtx,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentAmber.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.storefront_rounded, color: AppTheme.accentAmber, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              shopName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              isAr ? 'كود الانضمام للمحل (دعوة العمال)' : 'Shop Join Code (Invite Workers)',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Code Display Chip with Copy Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.accentAmber.withOpacity(0.4), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    shopCode,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: AppTheme.accentAmber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: shopCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isAr ? 'تم نسخ كود المحل ✓' : 'Shop code copied ✓')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.copy_rounded, size: 16, color: AppTheme.accentAmber),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Share Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentAmber,
                  foregroundColor: AppTheme.surfaceDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.share_rounded),
                label: Text(
                  isAr ? 'مشاركة كود المحل عبر WhatsApp' : 'Share Shop Code via WhatsApp',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  Navigator.of(dialogCtx).pop();
                  final message = isAr
                      ? 'مرحباً، للانضمام إلى محل ($shopName) على تطبيق TUSSI، استخدم كود الانضمام التالي عند التسجيل:\n\n👉 *$shopCode*\n\nرابط تحميل التطبيق: https://tussi.web.app'
                      : 'Hello, to join ($shopName) on the TUSSI app, use this shop join code when registering:\n\n👉 *$shopCode*\n\nApp link: https://tussi.web.app';
                  await SharePlus.instance.share(ShareParams(text: message));
                },
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(isAr ? 'إغلاق' : 'Close', style: TextStyle(color: AppTheme.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    final firestoreService = FirestoreService();
    final auth = Provider.of<app_auth.AuthProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final shopId = auth.appUser?.shopId ?? '';

    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── GitHub App Update Check ─────────────────────────────
            FutureBuilder<AppUpdateInfo?>(
              future: UpdateService.checkGithubUpdate(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final updateInfo = snapshot.data!;
                  final latestVersion = updateInfo.version;
                  final updateUrl = updateInfo.downloadUrl.isNotEmpty ? updateInfo.downloadUrl : updateInfo.url;
                  final changelog = updateInfo.changelog;

                  if (!kIsWeb &&
                      latestVersion.isNotEmpty &&
                      latestVersion != _kCurrentVersion) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.accentAmber.withOpacity(0.18),
                            AppTheme.surfaceCard,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.accentAmber.withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentAmber.withOpacity(0.08),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentAmber.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.system_update_rounded,
                                  color: AppTheme.accentAmber,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isAr ? 'تحديث جديد متوفر على GitHub 🚀' : 'New Update Available on GitHub 🚀',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentAmber,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'v$latestVersion',
                                  style: TextStyle(
                                    color: AppTheme.surfaceDark,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            changelog.isNotEmpty
                                ? changelog
                                : (isAr
                                    ? 'يتوفر تحديث جديد للتطبيق عبر GitHub. يرجى تنزيل النسخة الجديدة للحصول على آخر الميزات.'
                                    : 'A new version of the app is available on GitHub. Please download to update.'),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (ctx) => DownloadProgressDialog(
                                    currentVersion: _kCurrentVersion,
                                    latestVersion: latestVersion,
                                    updateUrl: updateUrl,
                                    isAr: isAr,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.file_download_rounded, size: 18),
                              label: Text(isAr ? 'تنزيل وتثبيت التحديث مباشرة 🚀' : 'Download & Install APK Directly 🚀'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentAmber,
                                foregroundColor: AppTheme.surfaceDark,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),

            // ─── Hero Shop Card ──────────────────────────────────────
            if (shopId.isNotEmpty)
              _buildHeroShopCard(
                context: context,
                firestoreService: firestoreService,
                shopId: shopId,
                isAr: isAr,
                userRole: auth.appUser?.role,
              ),

            // ─── Section 1: إدارة المحل والأقمشة (Shop & Fabric Operations) ───
            if (shopId.isNotEmpty && (auth.appUser?.role == 'shop_admin' || auth.appUser?.role == 'shop_employee' || auth.appUser?.email == 'hhcgjvhcnk@gmail.com')) ...[
              _buildSectionHeader(
                isAr ? 'إدارة المحل والأقمشة' : 'Shop & Fabric Management',
                Icons.tune_rounded,
              ),
              _buildGlassCard(
                context: context,
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentAmber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.settings_suggest_rounded, color: AppTheme.accentAmber, size: 22),
                      ),
                      title: Text(
                        isAr ? 'عمليات التحكم بالقماش السريعة' : 'Fabric Quick Actions',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Text(
                        isAr ? 'إضافة، تعديل الأسماء والأسعار، وإدارة الوحدات' : 'Add, edit names, prices & units',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
                      onTap: () => _showFabricActionsMenu(context, firestoreService, shopId),
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentAmber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.people_alt_rounded, color: AppTheme.accentAmber, size: 22),
                      ),
                      title: Text(
                        isAr ? 'أعضاء المحل وفريق العمل' : 'Shop Members & Team',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Text(
                        isAr ? 'عرض بيانات المشتركين والموظفين المسجلين' : 'View registered employees & partners',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
                      onTap: () => _showShopInfoBottomSheet(context, firestoreService, shopId),
                    ),
                  ],
                ),
              ),
            ],

            // ─── Section 2: المظهر والتخصيص (Appearance & System) ────
            _buildSectionHeader(
              isAr ? 'المظهر والتخصيص' : 'Appearance & System',
              Icons.palette_outlined,
            ),
            _buildGlassCard(
              context: context,
              child: Column(
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      iconColor: AppTheme.accentAmber,
                      collapsedIconColor: AppTheme.textMuted,
                      leading: Icon(
                        themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: AppTheme.accentAmber,
                      ),
                      title: Text(
                        isAr ? 'إعدادات المظهر والسمة' : 'Theme & Appearance Settings',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Text(
                        isAr
                            ? (themeProvider.useSmartTheme ? 'الوضع التلقائي مفعل' : (themeProvider.isDarkMode ? 'الوضع الداكن مفعل' : 'الوضع المضيء مفعل'))
                            : (themeProvider.useSmartTheme ? 'Smart Auto Active' : (themeProvider.isDarkMode ? 'Dark Mode Active' : 'Light Mode Active')),
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                          leading: Icon(
                            themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            color: AppTheme.accentAmber,
                            size: 20,
                          ),
                          title: Text(
                            context.tr('dark_mode'),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          trailing: Switch(
                            value: themeProvider.isDarkMode,
                            activeColor: AppTheme.accentAmber,
                            onChanged: (value) => themeProvider.toggleTheme(value),
                          ),
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                          leading: Icon(
                            Icons.schedule_rounded,
                            color: AppTheme.accentAmber,
                            size: 20,
                          ),
                          title: Text(
                            isAr ? 'الوضع الذكي التلقائي' : 'Smart Auto Mode',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          trailing: Switch(
                            value: themeProvider.useSmartTheme,
                            activeColor: AppTheme.accentAmber,
                            onChanged: (value) => themeProvider.setUseSmartTheme(value),
                          ),
                        ),
                        if (themeProvider.useSmartTheme) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16, top: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: themeProvider.lightStartTime,
                                      );
                                      if (time != null) {
                                        themeProvider.setLightStartTime(time);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceElevated,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppTheme.borderSubtle),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isAr ? 'بدء المضيء ☀️' : 'Light starts ☀️',
                                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            themeProvider.lightStartTime.format(context),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: themeProvider.darkStartTime,
                                      );
                                      if (time != null) {
                                        themeProvider.setDarkStartTime(time);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceElevated,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppTheme.borderSubtle),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isAr ? 'بدء المظلم 🌙' : 'Dark starts 🌙',
                                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            themeProvider.darkStartTime.format(context),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              isAr ? 'الثيمات الجاهزة للتطبيق (5 ثيمات):' : 'Ready Themes (5 Presets):',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.accentAmber),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...AppTheme.presets.entries.where((e) => e.key != 'custom').map((entry) {
                                final preset = entry.value;
                                final isSelected = themeProvider.currentPresetId == preset.id;

                                return InkWell(
                                  onTap: () => themeProvider.setPresetTheme(preset.id),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? preset.accentPrimary.withOpacity(0.2) : AppTheme.surfaceElevated,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? preset.accentPrimary : AppTheme.borderSubtle,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(preset.icon, size: 16, color: preset.accentPrimary),
                                        const SizedBox(width: 6),
                                        Text(
                                          isAr ? preset.nameAr : preset.nameEn,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            color: isSelected ? preset.accentPrimary : AppTheme.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showCustomThemeDialog(context, themeProvider),
                              icon: Icon(Icons.palette_rounded, color: AppTheme.accentAmber),
                              label: Text(
                                isAr ? 'إنشاء ثيم خاص 🎨 (Custom Theme)' : 'Create Custom Theme 🎨',
                                style: TextStyle(color: AppTheme.accentAmber, fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppTheme.accentAmber),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      iconColor: AppTheme.accentAmber,
                      collapsedIconColor: AppTheme.textMuted,
                      leading: Icon(Icons.translate_rounded, color: AppTheme.accentAmber),
                      title: Text(
                        isAr ? 'إعدادات اللغة' : 'Language Settings',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Text(
                        _getLanguageName(languageProvider.language),
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              _buildLanguageOption(
                                context,
                                languageProvider,
                                lang: AppLanguage.fr,
                                title: 'Français',
                                subtitle: isAr ? 'الفرنسية' : 'French',
                              ),
                              const Divider(height: 1),
                              _buildLanguageOption(
                                context,
                                languageProvider,
                                lang: AppLanguage.en,
                                title: 'English',
                                subtitle: isAr ? 'الإنجليزية' : 'English',
                              ),
                              const Divider(height: 1),
                              _buildLanguageOption(
                                context,
                                languageProvider,
                                lang: AppLanguage.ar,
                                title: 'العربية',
                                subtitle: isAr ? 'العربية' : 'Arabic',
                              ),
                              const Divider(height: 1),
                              _buildLanguageOption(
                                context,
                                languageProvider,
                                lang: AppLanguage.es,
                                title: 'Español',
                                subtitle: isAr ? 'الإسبانية' : 'Spanish',
                              ),
                              const Divider(height: 1),
                              _buildLanguageOption(
                                context,
                                languageProvider,
                                lang: AppLanguage.zh,
                                title: '中文 (Chinese)',
                                subtitle: isAr ? 'الصينية' : 'Chinese',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await languageProvider.saveLanguage();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(context.tr('settings_saved')),
                                      backgroundColor: AppTheme.successSurface,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.save_rounded, size: 18),
                              label: Text(context.tr('save_settings')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentAmber,
                                foregroundColor: AppTheme.surfaceDark,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── Section 3: المساعدة والتطبيق (Help & Resources) ────
            _buildSectionHeader(
              isAr ? 'المساعدة والتطبيق' : 'Help & Application',
              Icons.help_center_outlined,
            ),
            _buildGlassCard(
              context: context,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.menu_book_rounded, color: AppTheme.accentAmber, size: 22),
                    ),
                    title: Text(
                      isAr ? 'دليل الاستخدام والتعليمات' : 'User Guide & Instructions',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: Text(
                      isAr
                          ? 'شرح تفاعلي بالصور لكافة أزرار ومميزات التطبيق'
                          : 'Interactive visual guide for all app buttons & features',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const HelpGuideScreen(),
                        ),
                      );
                    },
                  ),
                  if (!kIsWeb) ...[
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentAmber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.qr_code_2_rounded, color: AppTheme.accentAmber, size: 22),
                      ),
                      title: Text(
                        isAr ? 'مشاركة ونشر التطبيق' : 'Share Application',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Text(
                        isAr ? 'مشاركة رابط تحميل النسخة مباشرة مع الشركاء' : 'Share app download link directly',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
                      onTap: () => _showShareAppDialog(context),
                    ),
                  ],
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.info_outline_rounded, color: AppTheme.accentAmber, size: 22),
                    ),
                    title: Text(
                      isAr ? 'تفاصيل التطبيق والمطور' : 'App Details & Developer',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: Text(
                      isAr ? 'معلومات النظام، الإصدار، وبيانات المطور' : 'System info, version & developer note',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
                    onTap: () => _showAboutDialog(context),
                  ),
                ],
              ),
            ),

            // ─── Section 4: لوحة المطور والتحكم العام (Super Admin) ────
            if (auth.appUser?.email == 'hhcgjvhcnk@gmail.com') ...[
              _buildSectionHeader(
                isAr ? 'لوحة المطور والتحكم العام' : 'Super Admin Panel',
                Icons.admin_panel_settings_rounded,
              ),
              _buildGlassCard(
                context: context,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.system_update_rounded, color: AppTheme.accentAmber, size: 22),
                  ),
                  title: Text(
                    isAr ? 'نشر تحديث جديد' : 'Publish App Update',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Text(
                    isAr ? 'رفع وإعلان تحديث جديد للمستخدمين' : 'Publish a new app update',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
                  onTap: () => _showPublishUpdateDialog(context, firestoreService),
                ),
              ),
            ],

            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.06),
                      ),
                    ),
                    child: Text(
                      'TUSSI • v$_kCurrentVersion',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentAmber,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'by mohammed bahayou',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showFabricActionsMenu(BuildContext context, FirestoreService firestoreService, String shopId) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) {
        return _buildGlassBottomSheet(
          context: ctx,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentAmber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.settings_suggest_rounded, color: AppTheme.accentAmber, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isAr ? 'إجراءات القماش السريعة' : 'Fabric Quick Actions',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.add_circle_outline_rounded, color: AppTheme.accentAmber),
                title: Text(
                  isAr ? 'إضافة قماش جديد' : 'Add New Fabric',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showAddFabricDialog(context, firestoreService, shopId);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.drive_file_rename_outline_rounded, color: AppTheme.accentAmber),
                title: Text(
                  isAr ? 'تعديل اسم القماش' : 'Edit Fabric Name',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showEditFabricNamePicker(context, firestoreService, shopId);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.edit_note_rounded, color: AppTheme.accentAmber),
                title: Text(
                  isAr ? 'تعديل سعر القماش' : 'Edit Fabric Price',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showEditFabricPricePicker(context, firestoreService, shopId);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.scale_rounded, color: AppTheme.accentAmber),
                title: Text(
                  isAr ? 'تعديل وحدة القماش' : 'Edit Fabric Unit',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showEditFabricUnitPicker(context, firestoreService, shopId);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.texture_rounded, color: AppTheme.error),
                title: Text(
                  isAr ? 'حذف قماش' : 'Delete Fabric',
                  style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showDeleteFabricPicker(context, firestoreService, shopId);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.straighten_rounded, color: AppTheme.error),
                title: Text(
                  isAr ? 'حذف الأمتار المحفوظة' : 'Delete Saved Lengths',
                  style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showDeleteLengthPicker(context, firestoreService, shopId);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showAddFabricDialog(BuildContext context, FirestoreService firestoreService, String shopId) {
    final dialogNameController = TextEditingController();
    final dialogPriceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        String? localUnit;
        String? validationError;
        final isAr = ctx.tr('tab_orders') == 'الطلبيات';

        return StatefulBuilder(
          builder: (context, setState) {
            return _buildGlassDialog(
              context: context,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentAmber.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.add_circle_outline_rounded, color: AppTheme.accentAmber, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          context.tr('add_new_fabric_type'),
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: dialogNameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: context.tr('fabric_type_name'),
                      ),
                      onChanged: (_) {
                        if (validationError != null) {
                          setState(() {
                            validationError = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: dialogPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: context.tr('fabric_price'),
                      ),
                      onChanged: (_) {
                        if (validationError != null) {
                          setState(() {
                            validationError = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('unit_choice'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RadioListTile<String>(
                      title: Text(context.tr('meter_label')),
                      value: 'meter',
                      groupValue: localUnit,
                      activeColor: AppTheme.accentAmber,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() {
                          localUnit = val;
                          validationError = null;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: Text(context.tr('kg_label')),
                      value: 'kg',
                      groupValue: localUnit,
                      activeColor: AppTheme.accentAmber,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() {
                          localUnit = val;
                          validationError = null;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: Text(context.tr('yard_label')),
                      value: 'yard',
                      groupValue: localUnit,
                      activeColor: AppTheme.accentAmber,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() {
                          localUnit = val;
                          validationError = null;
                        });
                      },
                    ),
                    if (validationError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        validationError!,
                        style: TextStyle(
                          color: AppTheme.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(context.tr('cancel'), style: TextStyle(color: AppTheme.textMuted)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentAmber,
                            foregroundColor: AppTheme.surfaceDark,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            final name = dialogNameController.text.trim();
                            final priceText = dialogPriceController.text.trim();
                            if (name.isEmpty) {
                              setState(() {
                                validationError = context.tr('fabric_name_required');
                              });
                              return;
                            }
                            if (priceText.isEmpty) {
                              setState(() {
                                validationError = context.tr('fabric_price_required');
                              });
                              return;
                            }
                            final price = double.tryParse(priceText);
                            if (price == null || price <= 0) {
                              setState(() {
                                validationError = context.tr('invalid_price');
                              });
                              return;
                            }
                            if (localUnit == null) {
                              setState(() {
                                validationError = context.tr('required_unit');
                              });
                              return;
                            }
                            
                            try {
                              await firestoreService.addFabricType(name, localUnit!, price, shopId);
                              if (context.mounted) {
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isAr ? 'تم إضافة القماش الجديد بنجاح ✓' : 'New fabric added successfully ✓'),
                                    backgroundColor: AppTheme.successSurface,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }
                            } catch (e) {
                              setState(() {
                                validationError = isAr ? 'حدث خطأ أثناء الإضافة' : 'Error adding fabric: $e';
                              });
                            }
                          },
                          child: Text(context.tr('add'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditFabricNamePicker(BuildContext context, FirestoreService firestoreService, String shopId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) {
        String searchQuery = '';
        final isAr = context.tr('tab_orders') == 'الطلبيات';

        return StreamBuilder<List<FabricType>>(
          stream: firestoreService.streamFabricTypes(shopId),
          builder: (context, snapshot) {
            final fabrics = snapshot.data ?? [];
            return StatefulBuilder(
              builder: (context, setState) {
                final filtered = fabrics.where((type) {
                  return AppTheme.matchesFuzzy(searchQuery, type.name);
                }).toList();

                return _buildGlassBottomSheet(
                  context: context,
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
                            isAr ? 'تعديل اسم قماش' : 'Edit Fabric Name',
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
                      TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: isAr ? 'بحث عن قماش...' : 'Search fabric...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (val) {
                          setState(() {
                            searchQuery = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: filtered.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    isAr ? 'لم يتم العثور على أقمشة' : 'No fabrics found',
                                    style: TextStyle(color: AppTheme.textMuted),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final type = filtered[idx];
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    title: Text(
                                      type.name,
                                      style: TextStyle(color: AppTheme.textPrimary),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.edit_rounded, color: AppTheme.accentAmber, size: 22),
                                      onPressed: () async {
                                        final controller = TextEditingController(text: type.name);
                                        final newName = await showDialog<String>(
                                          context: context,
                                          builder: (ctx) => _buildGlassDialog(
                                            context: ctx,
                                            maxWidth: 380,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme.accentAmber.withOpacity(0.15),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Icon(Icons.edit_rounded, color: AppTheme.accentAmber, size: 20),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Text(
                                                      isAr ? 'تعديل الاسم' : 'Edit Name',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                TextField(
                                                  controller: controller,
                                                  autofocus: true,
                                                  style: const TextStyle(color: Colors.white),
                                                  decoration: InputDecoration(
                                                    hintText: isAr ? 'الاسم الجديد' : 'New name',
                                                    filled: true,
                                                    fillColor: Colors.white.withOpacity(0.06),
                                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
                                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
                                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.accentAmber)),
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: OutlinedButton(
                                                        style: OutlinedButton.styleFrom(
                                                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                        ),
                                                        onPressed: () => Navigator.of(ctx).pop(),
                                                        child: Text(isAr ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Colors.white70)),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: AppTheme.accentAmber,
                                                          foregroundColor: Colors.black,
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                        ),
                                                        onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
                                                        child: Text(isAr ? 'حفظ' : 'Save', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                        if (newName != null && newName.isNotEmpty && newName != type.name) {
                                          await firestoreService.updateFabricName(type.name, newName, shopId);
                                          setState(() {});
                                        }
                                      },
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
      },
    );
  }

  void _showEditFabricPricePicker(BuildContext context, FirestoreService firestoreService, String shopId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) {
        String searchQuery = '';
        final isAr = context.tr('tab_orders') == 'الطلبيات';

        return StreamBuilder<List<FabricType>>(
          stream: firestoreService.streamFabricTypes(shopId),
          builder: (context, snapshot) {
            final fabrics = snapshot.data ?? [];
            return StatefulBuilder(
              builder: (context, setState) {
                final filtered = fabrics.where((type) {
                  return AppTheme.matchesFuzzy(searchQuery, type.name);
                }).toList();

                return _buildGlassBottomSheet(
                  context: context,
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
                            isAr ? 'تعديل سعر قماش' : 'Edit Fabric Price',
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
                      TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: isAr ? 'بحث عن قماش...' : 'Search fabric...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (val) {
                          setState(() {
                            searchQuery = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: filtered.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    isAr ? 'لم يتم العثور على أقمشة' : 'No fabrics found',
                                    style: TextStyle(color: AppTheme.textMuted),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final type = filtered[idx];
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    title: Text(
                                      type.name,
                                      style: TextStyle(color: AppTheme.textPrimary),
                                    ),
                                    subtitle: Text(
                                      '${type.price.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} DA / ${type.unit == 'kg' ? (isAr ? 'كغ' : 'kg') : (isAr ? 'متر' : 'm')}',
                                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.edit_rounded, color: AppTheme.accentAmber, size: 22),
                                      onPressed: () async {
                                        final priceController = TextEditingController(
                                          text: type.price.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), ''),
                                        );
                                        final newPrice = await showDialog<double>(
                                          context: context,
                                          builder: (dialogCtx) => _buildGlassDialog(
                                            context: dialogCtx,
                                            maxWidth: 380,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme.accentAmber.withOpacity(0.15),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Icon(Icons.attach_money_rounded, color: AppTheme.accentAmber, size: 20),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Text(
                                                      isAr ? 'تعديل سعر قماش' : 'Edit Fabric Price',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 14),
                                                Text(
                                                  isAr 
                                                      ? 'أدخل السعر الجديد لقماش "${type.name}":' 
                                                      : 'Enter new price for fabric "${type.name}":',
                                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                                ),
                                                const SizedBox(height: 12),
                                                TextField(
                                                  controller: priceController,
                                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                  autofocus: true,
                                                  style: const TextStyle(color: Colors.white),
                                                  decoration: InputDecoration(
                                                    suffixText: isAr ? 'د.ج' : 'DA',
                                                    filled: true,
                                                    fillColor: Colors.white.withOpacity(0.06),
                                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
                                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
                                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.accentAmber)),
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: OutlinedButton(
                                                        style: OutlinedButton.styleFrom(
                                                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                        ),
                                                        onPressed: () => Navigator.of(dialogCtx).pop(),
                                                        child: Text(isAr ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Colors.white70)),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: AppTheme.accentAmber,
                                                          foregroundColor: Colors.black,
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                        ),
                                                        onPressed: () {
                                                          final val = double.tryParse(priceController.text);
                                                          if (val != null && val >= 0) {
                                                            Navigator.of(dialogCtx).pop(val);
                                                          }
                                                        },
                                                        child: Text(isAr ? 'حفظ' : 'Save', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                        if (newPrice != null) {
                                          await firestoreService.updateFabricPrice(type.name, newPrice, shopId);
                                          setState(() {});
                                        }
                                      },
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
      },
    );
  }

  void _showEditFabricUnitPicker(BuildContext context, FirestoreService firestoreService, String shopId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) {
        String searchQuery = '';
        final isAr = context.tr('tab_orders') == 'الطلبيات';

        return StreamBuilder<List<FabricType>>(
          stream: firestoreService.streamFabricTypes(shopId),
          builder: (context, snapshot) {
            final fabrics = snapshot.data ?? [];
            return StatefulBuilder(
              builder: (context, setState) {
                final filtered = fabrics.where((type) {
                  return AppTheme.matchesFuzzy(searchQuery, type.name);
                }).toList();

                return _buildGlassBottomSheet(
                  context: context,
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
                            isAr ? 'تعديل وحدة القماش' : 'Edit Fabric Unit',
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
                      TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: isAr ? 'بحث عن قماش...' : 'Search fabric...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (val) {
                          setState(() {
                            searchQuery = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: filtered.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    isAr ? 'لم يتم العثور على أقمشة' : 'No fabrics found',
                                    style: TextStyle(color: AppTheme.textMuted),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final type = filtered[idx];
                                  final unitLabel = type.unit == 'kg'
                                      ? (isAr ? 'الكيلوجرام (كغ)' : 'Kilogram (kg)')
                                      : (type.unit == 'yard'
                                          ? (isAr ? 'اليارد' : 'Yard')
                                          : (isAr ? 'المتر' : 'Meter'));

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    title: Text(
                                      type.name,
                                      style: TextStyle(color: AppTheme.textPrimary),
                                    ),
                                    subtitle: Text(
                                      '${isAr ? 'الوحدة الحالية:' : 'Current Unit:'} $unitLabel',
                                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.edit_rounded, color: AppTheme.accentAmber, size: 22),
                                      onPressed: () async {
                                        String selectedUnit = type.unit.isNotEmpty ? type.unit : 'meter';
                                        final newUnit = await showDialog<String>(
                                          context: context,
                                          builder: (dialogCtx) => StatefulBuilder(
                                            builder: (ctx, setDialogState) => _buildGlassDialog(
                                              context: ctx,
                                              maxWidth: 400,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(8),
                                                        decoration: BoxDecoration(
                                                          color: AppTheme.accentAmber.withOpacity(0.15),
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: Icon(Icons.straighten_rounded, color: AppTheme.accentAmber, size: 20),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Text(
                                                        isAr ? 'تعديل وحدة القماش' : 'Edit Fabric Unit',
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    isAr
                                                        ? 'اختر الوحدة لقماش "${type.name}":'
                                                        : 'Select unit for "${type.name}":',
                                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  RadioListTile<String>(
                                                    title: Text(context.tr('meter_label'), style: const TextStyle(color: Colors.white)),
                                                    value: 'meter',
                                                    groupValue: selectedUnit,
                                                    activeColor: AppTheme.accentAmber,
                                                    contentPadding: EdgeInsets.zero,
                                                    onChanged: (val) {
                                                      if (val != null) setDialogState(() => selectedUnit = val);
                                                    },
                                                  ),
                                                  RadioListTile<String>(
                                                    title: Text(context.tr('kg_label'), style: const TextStyle(color: Colors.white)),
                                                    value: 'kg',
                                                    groupValue: selectedUnit,
                                                    activeColor: AppTheme.accentAmber,
                                                    contentPadding: EdgeInsets.zero,
                                                    onChanged: (val) {
                                                      if (val != null) setDialogState(() => selectedUnit = val);
                                                    },
                                                  ),
                                                  RadioListTile<String>(
                                                    title: Text(context.tr('yard_label'), style: const TextStyle(color: Colors.white)),
                                                    value: 'yard',
                                                    groupValue: selectedUnit,
                                                    activeColor: AppTheme.accentAmber,
                                                    contentPadding: EdgeInsets.zero,
                                                    onChanged: (val) {
                                                      if (val != null) setDialogState(() => selectedUnit = val);
                                                    },
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: OutlinedButton(
                                                          style: OutlinedButton.styleFrom(
                                                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                          ),
                                                          onPressed: () => Navigator.of(ctx).pop(),
                                                          child: Text(isAr ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Colors.white70)),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: AppTheme.accentAmber,
                                                            foregroundColor: Colors.black,
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                          ),
                                                          onPressed: () => Navigator.of(ctx).pop(selectedUnit),
                                                          child: Text(isAr ? 'حفظ' : 'Save', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                        if (newUnit != null && newUnit != type.unit) {
                                          await firestoreService.updateFabricUnit(type.name, newUnit, shopId);
                                          setState(() {});
                                        }
                                      },
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
      },
    );
  }

  void _showDeleteFabricPicker(BuildContext context, FirestoreService firestoreService, String shopId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) {
        String searchQuery = '';
        final isAr = context.tr('tab_orders') == 'الطلبيات';

        return StreamBuilder<List<FabricType>>(
          stream: firestoreService.streamFabricTypes(shopId),
          builder: (context, snapshot) {
            final fabrics = snapshot.data ?? [];
            return StatefulBuilder(
              builder: (context, setState) {
                final filtered = fabrics.where((type) {
                  return AppTheme.matchesFuzzy(searchQuery, type.name);
                }).toList();

                return _buildGlassBottomSheet(
                  context: context,
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
                            isAr ? 'حذف قماش' : 'Delete Fabric',
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
                      TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: isAr ? 'بحث عن قماش...' : 'Search fabric...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (val) {
                          setState(() {
                            searchQuery = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: filtered.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    isAr ? 'لم يتم العثور على أقمشة' : 'No fabrics found',
                                    style: TextStyle(color: AppTheme.textMuted),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final type = filtered[idx];
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    title: Text(
                                      type.name,
                                      style: TextStyle(color: AppTheme.textPrimary),
                                    ),
                                    subtitle: Text(
                                      '${type.price.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} DA / ${type.unit == 'kg' ? (isAr ? 'كغ' : 'kg') : (isAr ? 'متر' : 'm')}',
                                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 22),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => _buildGlassDialog(
                                            context: ctx,
                                            maxWidth: 380,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme.error.withOpacity(0.15),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Text(
                                                      isAr ? 'حذف القماش' : 'Delete Fabric',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 14),
                                                Text(
                                                  isAr 
                                                      ? 'هل أنت متأكد من حذف نوع القماش "${type.name}" نهائياً؟' 
                                                      : 'Are you sure you want to delete fabric "${type.name}" permanently?',
                                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4),
                                                ),
                                                const SizedBox(height: 20),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: OutlinedButton(
                                                        style: OutlinedButton.styleFrom(
                                                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                        ),
                                                        onPressed: () => Navigator.of(ctx).pop(false),
                                                        child: Text(isAr ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Colors.white70)),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: AppTheme.error,
                                                          foregroundColor: Colors.white,
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                        ),
                                                        onPressed: () => Navigator.of(ctx).pop(true),
                                                        child: Text(isAr ? 'حذف' : 'Delete', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                        if (confirm == true) {
                                          await firestoreService.deleteFabricType(type.name, shopId);
                                          fabrics.removeWhere((t) => t.name == type.name);
                                          setState(() {});
                                        }
                                      },
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
      },
    );
  }

  void _showDeleteLengthPicker(BuildContext context, FirestoreService firestoreService, String shopId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) {
        String? selectedFabric;
        String searchQuery = '';
        final isAr = context.tr('tab_orders') == 'الطلبيات';

        final fabricTypesStream = firestoreService.streamFabricTypes(shopId);
        Stream<List<double>>? savedLengthsStream;
        String? lastFabricType;

        return StatefulBuilder(
          builder: (context, setState) {
            if (selectedFabric != null && selectedFabric != lastFabricType) {
              lastFabricType = selectedFabric;
              savedLengthsStream = firestoreService.streamSavedLengthsForFabric(selectedFabric!, shopId);
            }

            if (selectedFabric == null) {
              // STEP 1: Select fabric type
              return StreamBuilder<List<FabricType>>(
                stream: fabricTypesStream,
                builder: (context, snapshot) {
                  final fabrics = snapshot.data ?? [];
                  final filteredFabrics = fabrics.where((type) {
                    return AppTheme.matchesFuzzy(searchQuery, type.name);
                  }).toList();

                  return _buildGlassBottomSheet(
                    context: context,
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
                              isAr ? 'إدارة الأمتار: اختر القماش' : 'Manage Lengths: Select Fabric',
                              style: const TextStyle(
                                fontSize: 16,
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
                        TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: isAr ? 'بحث عن قماش...' : 'Search fabric...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (val) {
                            setState(() {
                              searchQuery = val;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.4,
                          ),
                          child: filteredFabrics.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Center(
                                    child: Text(
                                      isAr ? 'لم يتم العثور على أقمشة' : 'No fabrics found',
                                      style: TextStyle(color: AppTheme.textMuted),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: filteredFabrics.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1),
                                  itemBuilder: (context, idx) {
                                    final type = filteredFabrics[idx];
                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      title: Text(
                                        type.name,
                                        style: TextStyle(color: AppTheme.textPrimary),
                                      ),
                                      trailing: Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: AppTheme.textSecondary,
                                        size: 14,
                                      ),
                                      onTap: () {
                                        setState(() {
                                          selectedFabric = type.name;
                                          searchQuery = ''; // Reset search query for next step
                                        });
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              );
            } else {
              // STEP 2: Show lengths for selected fabric
              return StreamBuilder<List<double>>(
                stream: savedLengthsStream,
                builder: (context, snapshot) {
                  final lengths = snapshot.data ?? [];
                  final filtered = lengths.where((len) {
                    final str = len.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
                    return str.contains(searchQuery);
                  }).toList();

                  return _buildGlassBottomSheet(
                    context: context,
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
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_rounded),
                              onPressed: () {
                                setState(() {
                                  selectedFabric = null;
                                  searchQuery = '';
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isAr ? 'حذف الأمتار: $selectedFabric' : 'Delete Lengths: $selectedFabric',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: isAr ? 'بحث عن مقاس...' : 'Search size...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (val) {
                            setState(() {
                              searchQuery = val;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.4,
                          ),
                          child: filtered.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Center(
                                    child: Text(
                                      isAr ? 'لم يتم العثور على مقاسات محفوظة' : 'No saved sizes found',
                                      style: TextStyle(color: AppTheme.textMuted),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: filtered.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1),
                                  itemBuilder: (context, idx) {
                                    final len = filtered[idx];
                                    final displayStr = len.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      title: Text(
                                        displayStr,
                                        style: TextStyle(color: AppTheme.textPrimary),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 22),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                             builder: (ctx) => _buildGlassDialog(
                                               context: ctx,
                                               maxWidth: 380,
                                               child: Column(
                                                 mainAxisSize: MainAxisSize.min,
                                                 crossAxisAlignment: CrossAxisAlignment.stretch,
                                                 children: [
                                                   Row(
                                                     children: [
                                                       Container(
                                                         padding: const EdgeInsets.all(8),
                                                         decoration: BoxDecoration(
                                                           color: AppTheme.error.withOpacity(0.15),
                                                           borderRadius: BorderRadius.circular(10),
                                                         ),
                                                         child: Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                                                       ),
                                                       const SizedBox(width: 10),
                                                       Text(
                                                         isAr ? 'ط­ط°ظپ ط§ظ„ظ…ظ‚ط§ط³' : 'Delete Size',
                                                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                                       ),
                                                     ],
                                                   ),
                                                   const SizedBox(height: 14),
                                                   Text(
                                                     isAr 
                                                         ? 'ظ‡ظ„ ط£ظ†طھ ظ…طھط£ظƒط¯ ظ…ظ† ط­ط°ظپ ط§ظ„ظ…ظ‚ط§ط³ "$displayStr" ظ†ظ‡ط§ط¦ظٹط§ظ‹ ظ„ظ‚ظ…ط§ط´ "$selectedFabric"طں' 
                                                         : 'Are you sure you want to delete size "$displayStr" permanently for "$selectedFabric"?',
                                                     style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4),
                                                   ),
                                                   const SizedBox(height: 20),
                                                   Row(
                                                     children: [
                                                       Expanded(
                                                         child: OutlinedButton(
                                                           style: OutlinedButton.styleFrom(
                                                             side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                           ),
                                                           onPressed: () => Navigator.of(ctx).pop(false),
                                                           child: Text(isAr ? 'ط¥ظ„ط؛ط§ط،' : 'Cancel', style: const TextStyle(color: Colors.white70)),
                                                         ),
                                                       ),
                                                       const SizedBox(width: 10),
                                                       Expanded(
                                                         child: ElevatedButton(
                                                           style: ElevatedButton.styleFrom(
                                                             backgroundColor: AppTheme.error,
                                                             foregroundColor: Colors.white,
                                                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                           ),
                                                           onPressed: () => Navigator.of(ctx).pop(true),
                                                           child: Text(isAr ? 'ط­ط°ظپ' : 'Delete', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                         ),
                                                       ),
                                                     ],
                                                   ),
                                                 ],
                                               ),
                                             )
                                          );
                                          if (confirm == true) {
                                            await firestoreService.deleteSavedLengthForFabric(selectedFabric!, len, shopId);
                                            setState(() {});
                                          }
                                        },
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
            }
          },
        );
      },
    );
  }

  String _getLanguageName(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.fr:
        return 'Français';
      case AppLanguage.en:
        return 'English';
      case AppLanguage.ar:
        return 'العربية';
      case AppLanguage.es:
        return 'Español';
      case AppLanguage.zh:
        return '中文 (Chinese)';
    }
  }

  Widget _buildLanguageOption(
    BuildContext context,
    LanguageProvider provider, {
    required AppLanguage lang,
    required String title,
    required String subtitle,
  }) {
    final isSelected = provider.language == lang;

    return InkWell(
      onTap: () => provider.setLanguage(lang),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accentAmber.withValues(alpha: 0.12)
                    : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.language_rounded,
                color: isSelected ? AppTheme.accentAmber : AppTheme.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppTheme.accentAmber,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  // ─── Show "Publish App Update" Dialog ──────────────────────────
  void _showPublishUpdateDialog(BuildContext context, FirestoreService firestoreService) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    final versionController = TextEditingController();
    final urlController = TextEditingController();
    final changelogController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        String? errorText;

        return StatefulBuilder(
          builder: (context, setState) {
            return _buildGlassDialog(
              context: context,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentAmber.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.system_update_rounded, color: AppTheme.accentAmber, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isAr ? 'نشر تحديث جديد' : 'Publish App Update',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      isAr ? 'رقم النسخة الجديدة (مثال: 3.0.6):' : 'New Version Name (e.g. 3.0.6):',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: versionController,
                      style: TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: '3.0.6',
                        hintStyle: TextStyle(color: AppTheme.textMuted),
                      ),
                      onChanged: (val) {
                        if (errorText != null) setState(() => errorText = null);
                        if (val.trim().isNotEmpty && urlController.text.isEmpty) {
                          urlController.text =
                              'https://github.com/Gt2433/TUSSI/releases/download/v${val.trim()}/app-release.apk';
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isAr ? 'رابط تحميل ملف APK المباشر:' : 'Direct APK Download Link:',
                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        InkWell(
                          onTap: () {
                            final ver = versionController.text.trim();
                            if (ver.isNotEmpty) {
                              urlController.text =
                                  'https://github.com/Gt2433/TUSSI/releases/download/v$ver/app-release.apk';
                              setState(() {});
                            }
                          },
                          child: Text(
                            isAr ? '🔗 رابط GitHub' : '🔗 GitHub Link',
                            style: TextStyle(color: AppTheme.accentAmber, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: urlController,
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'https://github.com/Gt2433/TUSSI/releases/download/v3.0.6/app-release.apk',
                        hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                      onChanged: (_) {
                        if (errorText != null) setState(() => errorText = null);
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isAr ? 'ما الجديد في هذا التحديث (اختياري):' : 'Changelog (Optional):',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: changelogController,
                      maxLines: 2,
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: isAr ? 'مثال: تحسينات في سرعة البحث، وإضافة شريط التحميل المباشر...' : 'e.g. Performance improvements...',
                        hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorText!,
                        style: TextStyle(color: AppTheme.error, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(isAr ? 'إلغاء' : 'Cancel', style: TextStyle(color: AppTheme.textMuted)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final version = versionController.text.trim();
                            final url = urlController.text.trim();
                            final changelog = changelogController.text.trim();

                            if (version.isEmpty) {
                              setState(() => errorText = isAr ? 'يرجى كتابة رقم النسخة' : 'Version name is required');
                              return;
                            }
                            if (url.isEmpty || !url.startsWith('http')) {
                              setState(() => errorText = isAr ? 'يرجى كتابة رابط صحيح يبدأ بـ http' : 'A valid HTTP link is required');
                              return;
                            }

                            try {
                              await firestoreService.publishAppUpdate(version, url, changelog: changelog);
                              if (context.mounted) {
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isAr ? 'تم نشر التحديث بنجاح' : 'Update published successfully'),
                                    backgroundColor: AppTheme.successSurface,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }
                            } catch (e) {
                              setState(() => errorText = isAr ? 'حدث خطأ: $e' : 'Error: $e');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentAmber,
                            foregroundColor: AppTheme.surfaceDark,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(isAr ? 'نشر الآن' : 'Publish Now', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Show "Shop & Partners Info" Bottom Sheet ──────────────────
  void _showShopInfoBottomSheet(BuildContext context, FirestoreService firestoreService, String shopId) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';

    if (shopId.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return _buildGlassBottomSheet(
              context: context,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppTheme.borderSubtle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Shop Details Stream
                  StreamBuilder<Map<String, dynamic>?>(
                    stream: firestoreService.streamShopDetails(shopId),
                    builder: (context, shopSnapshot) {
                      if (!shopSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final shopData = shopSnapshot.data;
                      if (shopData == null) {
                        return Text(isAr ? 'لم يتم العثور على بيانات المحل' : 'Shop data not found');
                      }

                      final shopName = shopData['name'] as String? ?? 'محل غير معروف';
                      final inviteCode = shopData['inviteCode'] as String? ?? '';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'بيانات المحل' : 'Shop Details',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentAmber,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceCard,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentAmber.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.store_rounded, color: AppTheme.accentAmber, size: 24),
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
                                      if (inviteCode.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          '${isAr ? "كود الدعوة:" : "Invite Code:"} $inviteCode',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Staff List
                  Text(
                    isAr ? 'الشركاء والموظفون في المحل' : 'Partners & Staff',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentAmber,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: StreamBuilder<List<AppUser>>(
                      stream: firestoreService.streamUsersInShop(shopId),
                      builder: (context, usersSnapshot) {
                        if (usersSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final users = usersSnapshot.data ?? [];
                        if (users.isEmpty) {
                          return Center(
                            child: Text(
                              isAr ? 'لا يوجد شركاء مسجلين بعد.' : 'No registered partners yet.',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          );
                        }

                        return ListView.separated(
                          controller: scrollController,
                          itemCount: users.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final user = users[index];
                            final name = user.displayName;
                            final email = user.email;

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.borderSubtle),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppTheme.textMuted.withValues(alpha: 0.1),
                                    child: Icon(
                                      Icons.person_rounded,
                                      color: AppTheme.textMuted,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          email,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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

  void _showCustomThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    final colors = [
      const Color(0xFFF5C842), // Gold / Amber
      const Color(0xFFEC4899), // Pink / Rose
      const Color(0xFFA855F7), // Purple / Violet
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF38BDF8), // Cyan / Sky
      const Color(0xFF10B981), // Emerald
      const Color(0xFF84CC16), // Lime
      const Color(0xFFF97316), // Orange
      const Color(0xFFEF4444), // Crimson / Red
      const Color(0xFFD4D4D4), // Silver / White
    ];

    Color selectedColor = AppTheme.accentAmber;
    bool selectedIsDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return _buildGlassDialog(
            context: context,
            maxWidth: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selectedColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selectedColor.withOpacity(0.4)),
                      ),
                      child: Icon(Icons.palette_rounded, color: selectedColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isAr ? 'إنشاء ثيم مخصص' : 'Create Custom Theme',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  isAr ? 'اختر اللون الرئيسي للتطبيق:' : 'Select Primary Accent Color:',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: colors.map((c) {
                    final isSelected = selectedColor.value == c.value;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedColor = c;
                        });
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.white24,
                            width: isSelected ? 3 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: c.withOpacity(0.6), blurRadius: 12, spreadRadius: 2)]
                              : [],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded, color: Colors.black, size: 24)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text(
                  isAr ? 'اختر خلفية التطبيق:' : 'Select Background Mode:',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        avatar: const Icon(Icons.dark_mode_rounded, size: 16),
                        label: Text(isAr ? 'داكن 🌙' : 'Dark 🌙'),
                        selected: selectedIsDark,
                        selectedColor: selectedColor,
                        onSelected: (val) {
                          setDialogState(() {
                            selectedIsDark = true;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        avatar: const Icon(Icons.light_mode_rounded, size: 16),
                        label: Text(isAr ? 'مضيء ☀️' : 'Light ☀️'),
                        selected: !selectedIsDark,
                        selectedColor: selectedColor,
                        onSelected: (val) {
                          setDialogState(() {
                            selectedIsDark = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(isAr ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Colors.white70)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedColor,
                          foregroundColor: selectedIsDark ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          themeProvider.setCustomTheme(
                            primaryColor: selectedColor,
                            isDark: selectedIsDark,
                          );
                        },
                        child: Text(isAr ? 'تطبيق الثيم' : 'Apply Theme', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

