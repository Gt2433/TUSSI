import 'package:flutter/material.dart';
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
import 'super_admin_screen.dart';
import '../models/user_model.dart';

class SettingsScreen extends StatelessWidget {
  final bool isTab;
  const SettingsScreen({super.key, this.isTab = false});

  static const String _kCurrentVersion = '2.0.0';

  // ─── Show "About App" Dialog ──────────────────────────────────
  void _showAboutDialog(BuildContext context) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    
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
              // Logo/Icon Container (Changed from standard info icon to Application Logo)
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
              const SizedBox(height: 20),
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
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 20),
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
                'Mohammed Bahyou (محمد باحيو)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isAr ? 'الإصدار الثاني: $_kCurrentVersion' : 'Version: $_kCurrentVersion',
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
      ),
    );
  }

  // ─── Show "Share App" Dialog ──────────────────────────────────
  void _showShareAppDialog(BuildContext context) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppTheme.surfaceCard,
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('app_updates').doc('latest').get(),
          builder: (context, snapshot) {
            String apkUrl = 'https://fantex.web.app';
            if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              apkUrl = data?['url'] as String? ?? apkUrl;
            }

            final qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${Uri.encodeComponent(apkUrl)}';

            return Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isAr ? 'مشاركة ونشر التطبيق' : 'Share Application',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isAr 
                        ? 'امسح رمز الـ QR التالي لتحميل التطبيق مباشرة على أي هاتف آخر:'
                        : 'Scan this QR Code to download the application directly to any other device:',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.network(
                      qrUrl,
                      width: 200,
                      height: 200,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          width: 200,
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 200,
                        height: 200,
                        color: AppTheme.surfaceDark,
                        child: const Icon(
                          Icons.qr_code_2_rounded,
                          size: 64,
                          color: Colors.white54,
                        ),
                      ),
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
                      icon: const Icon(Icons.share_rounded),
                      label: Text(
                        isAr ? 'مشاركة رابط التحميل' : 'Share Download Link',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final firestoreService = FirestoreService();
    final auth = context.watch<app_auth.AuthProvider>();
    final shopId = auth.appUser?.shopId ?? '';
    final isAr = context.tr('tab_orders') == 'الطلبيات';

    return Scaffold(
      appBar: isTab
          ? null
          : AppBar(
              title: Text(context.tr('app_settings')),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── App Update Check ────────────────────────────────
            StreamBuilder<Map<String, dynamic>?>(
              stream: firestoreService.streamLatestAppUpdate(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final updateData = snapshot.data!;
                  final latestVersion = updateData['version'] as String? ?? '';
                  final updateUrl = updateData['url'] as String? ?? '';

                  if (!kIsWeb &&
                      latestVersion.isNotEmpty &&
                      latestVersion != _kCurrentVersion &&
                      auth.appUser?.email != 'hhcgjvhcnk@gmail.com') {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.accentAmber.withValues(alpha: 0.15),
                            AppTheme.accentAmber.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.accentAmber.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentAmber.withValues(alpha: 0.05),
                            blurRadius: 15,
                            spreadRadius: 2,
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
                                  color: AppTheme.accentAmber.withValues(alpha: 0.2),
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
                                  isAr ? 'تحديث جديد متوفر!' : 'New Update Available!',
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
                            isAr
                                ? 'يتوفر تحديث جديد للتطبيق. يرجى تنزيل النسخة الجديدة للحصول على آخر الميزات والتحسينات.'
                                : 'A new version of the app is available. Please download the latest version to get the newest features and improvements.',
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
                              onPressed: () async {
                                final uri = Uri.parse(updateUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.download_rounded, size: 18),
                              label: Text(isAr ? 'تنزيل النسخة الجديدة' : 'Download New Version'),
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

            // ─── Group 1: Appearance & Language ─────────────────
            Text(
              isAr ? 'المظهر واللغة' : 'Appearance & Language',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentAmber,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                children: [
                  // Dark Mode Tile
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    leading: Icon(
                      themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: AppTheme.accentAmber,
                    ),
                    title: Text(
                      context.tr('dark_mode'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: Text(
                      themeProvider.isDarkMode ? context.tr('enabled') : context.tr('disabled'),
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      activeColor: AppTheme.accentAmber,
                      onChanged: (value) => themeProvider.toggleTheme(value),
                    ),
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  // Language Selection Header/Info
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: Icon(Icons.translate_rounded, color: AppTheme.accentAmber),
                    title: Text(
                      context.tr('language'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildLanguageOption(
                          context,
                          languageProvider,
                          lang: AppLanguage.fr,
                          title: 'Français (Base)',
                          subtitle: 'French',
                        ),
                        const Divider(height: 1),
                        _buildLanguageOption(
                          context,
                          languageProvider,
                          lang: AppLanguage.en,
                          title: 'English',
                          subtitle: 'الإنجليزية',
                        ),
                        const Divider(height: 1),
                        _buildLanguageOption(
                          context,
                          languageProvider,
                          lang: AppLanguage.ar,
                          title: 'العربية',
                          subtitle: 'Arabic',
                        ),
                        const Divider(height: 1),
                        _buildLanguageOption(
                          context,
                          languageProvider,
                          lang: AppLanguage.es,
                          title: 'Español',
                          subtitle: 'Spanish',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ─── Group 2: Shop & Data Management (Admins & Employees) ────
            if (auth.appUser?.role == 'shop_admin' || auth.appUser?.role == 'shop_employee' || auth.appUser?.email == 'hhcgjvhcnk@gmail.com') ...[
              Text(
                isAr ? 'إدارة بيانات المحل' : 'Shop Data Management',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentAmber,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  children: [
                    // Delete Fabric Type
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: Icon(Icons.texture_rounded, color: AppTheme.error),
                      title: Text(
                        isAr ? 'حذف قماش' : 'Delete Fabric',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
                      onTap: () => _showDeleteFabricPicker(context, firestoreService, shopId),
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    // Delete Saved Lengths
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: Icon(Icons.straighten_rounded, color: AppTheme.error),
                      title: Text(
                        isAr ? 'حذف الأمتار المحفوظة' : 'Delete Saved Lengths',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
                      onTap: () => _showDeleteLengthPicker(context, firestoreService, shopId),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // ─── Group 3: Super Admin Panel (Only Developer/Owner Email) ───
            if (auth.appUser?.email == 'hhcgjvhcnk@gmail.com') ...[
              Text(
                isAr ? 'التحكم العام' : 'Global Admin Control',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentAmber,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: Icon(Icons.admin_panel_settings_rounded, color: AppTheme.accentAmber),
                      title: Text(
                        isAr ? 'إدارة المحلات وتوليد الأكواد' : 'Manage Shops & Activation Codes',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SuperAdminScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: Icon(Icons.system_update_rounded, color: AppTheme.accentAmber),
                      title: Text(
                        isAr ? 'نشر تحديث جديد' : 'Publish App Update',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
                      onTap: () => _showPublishUpdateDialog(context, firestoreService),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // ─── Group 3.5: Shop & Partners Info (For Admins & Employees) ───
            if (shopId.isNotEmpty) ...[
              Text(
                isAr ? 'المحل والشركاء' : 'Shop & Partners',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentAmber,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Icon(Icons.people_alt_rounded, color: AppTheme.accentAmber),
                  title: Text(
                    isAr ? 'أعضاء المحل وبيانات المشتركين' : 'Shop Members & Partners',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
                  onTap: () => _showShopInfoBottomSheet(context, firestoreService, shopId),
                ),
              ),
              const SizedBox(height: 32),
            ],

            // ─── Group 4: Application Info (About App) ───────────
            Text(
              isAr ? 'عن التطبيق' : 'About Application',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentAmber,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: Icon(Icons.info_outline_rounded, color: AppTheme.accentAmber),
                    title: Text(
                      isAr ? 'تفاصيل التطبيق والمطور' : 'App Details & Developer',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
                    onTap: () => _showAboutDialog(context),
                  ),
                  if (!kIsWeb) ...[
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: Icon(Icons.qr_code_2_rounded, color: AppTheme.accentAmber),
                      title: Text(
                        isAr ? 'مشاركة ونشر التطبيق' : 'Share Application',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
                      onTap: () => _showShareAppDialog(context),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 48),
            Center(
              child: Text(
                'by mohammed bahayou',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showDeleteFabricPicker(BuildContext context, FirestoreService firestoreService, String shopId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                  return type.name.toLowerCase().contains(searchQuery.toLowerCase());
                }).toList();

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
                                          builder: (ctx) => AlertDialog(
                                            title: Text(isAr ? 'حذف القماش' : 'Delete Fabric'),
                                            content: Text(isAr 
                                                ? 'هل أنت متأكد من حذف نوع القماش "${type.name}" نهائياً؟' 
                                                : 'Are you sure you want to delete fabric "${type.name}" permanently?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(ctx).pop(false),
                                                child: Text(isAr ? 'إلغاء' : 'Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.of(ctx).pop(true),
                                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                                child: Text(isAr ? 'حذف' : 'Delete'),
                                              ),
                                            ],
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
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                    return type.name.toLowerCase().contains(searchQuery.toLowerCase());
                  }).toList();

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
                                            builder: (ctx) => AlertDialog(
                                              title: Text(isAr ? 'حذف المقاس' : 'Delete Size'),
                                              content: Text(isAr 
                                                  ? 'هل أنت متأكد من حذف المقاس "$displayStr" نهائياً لقماش "$selectedFabric"؟' 
                                                  : 'Are you sure you want to delete size "$displayStr" permanently for "$selectedFabric"?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(ctx).pop(false),
                                                  child: Text(isAr ? 'إلغاء' : 'Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.of(ctx).pop(true),
                                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                                  child: Text(isAr ? 'حذف' : 'Delete'),
                                                ),
                                              ],
                                            ),
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

    showDialog(
      context: context,
      builder: (ctx) {
        String? errorText;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Icon(Icons.system_update_rounded, color: AppTheme.accentAmber),
                  const SizedBox(width: 10),
                  Text(
                    isAr ? 'نشر تحديث جديد' : 'Publish App Update',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'رقم النسخة الجديدة (مثال: 1.1.0):' : 'New Version Name (e.g. 1.1.0):',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: versionController,
                      style: TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: '1.1.0',
                        hintStyle: TextStyle(color: AppTheme.textMuted),
                      ),
                      onChanged: (_) {
                        if (errorText != null) setState(() => errorText = null);
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isAr ? 'رابط تحميل النسخة (ميقا، فايربيس...):' : 'Download Link (Mega, Firebase...):',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: urlController,
                      style: TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'https://...',
                        hintStyle: TextStyle(color: AppTheme.textMuted),
                      ),
                      onChanged: (_) {
                        if (errorText != null) setState(() => errorText = null);
                      },
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorText!,
                        style: TextStyle(color: AppTheme.error, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(isAr ? 'إلغاء' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final version = versionController.text.trim();
                    final url = urlController.text.trim();

                    if (version.isEmpty) {
                      setState(() => errorText = isAr ? 'يرجى كتابة رقم النسخة' : 'Version name is required');
                      return;
                    }
                    if (url.isEmpty || !url.startsWith('http')) {
                      setState(() => errorText = isAr ? 'يرجى كتابة رابط صحيح يبدأ بـ http' : 'A valid HTTP link is required');
                      return;
                    }

                    try {
                      await firestoreService.publishAppUpdate(version, url);
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
                  child: Text(isAr ? 'نشر الآن' : 'Publish Now'),
                ),
              ],
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
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
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
                            final role = user.role ?? 'shop_employee';

                            String roleText = isAr ? 'موظف' : 'Employee';
                            if (role == 'shop_admin') {
                              roleText = isAr ? 'مدير المحل' : 'Shop Admin';
                            }

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
                                    backgroundColor: role == 'shop_admin'
                                        ? AppTheme.accentAmber.withValues(alpha: 0.15)
                                        : AppTheme.textMuted.withValues(alpha: 0.1),
                                    child: Icon(
                                      role == 'shop_admin'
                                          ? Icons.person_rounded
                                          : Icons.person_outline_rounded,
                                      color: role == 'shop_admin' ? AppTheme.accentAmber : AppTheme.textMuted,
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: role == 'shop_admin'
                                          ? AppTheme.accentAmber.withValues(alpha: 0.15)
                                          : AppTheme.borderSubtle.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      roleText,
                                      style: TextStyle(
                                        color: role == 'shop_admin'
                                            ? AppTheme.accentAmber
                                            : AppTheme.textSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
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
}
