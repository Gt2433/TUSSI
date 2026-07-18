import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';

class SubscriptionExpiredScreen extends StatelessWidget {
  final String shopName;
  final DateTime? expiresAt;
  final String inviteCode;

  const SubscriptionExpiredScreen({
    super.key,
    required this.shopName,
    this.expiresAt,
    required this.inviteCode,
  });

  Future<void> _contactAdmin() async {
    final message =
        'السلام عليكم، أريد تجديد تفعيل اشتراك محل ($shopName) كود الدعوة ($inviteCode) في تطبيق tussi.';
    final encodedMessage = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/213655603829?text=$encodedMessage');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);

    String expiryText = '';
    if (expiresAt != null) {
      final dateStr = '${expiresAt!.day}/${expiresAt!.month}/${expiresAt!.year}';
      expiryText = isAr ? 'انتهى بتاريخ: $dateStr' : 'Expired on: $dateStr';
    } else {
      expiryText = isAr ? 'الاشتراك غير نشط حالياً' : 'Subscription is currently inactive';
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.surfaceGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Warning Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.accentAmber.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.accentAmber,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // App Logo Name
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppTheme.accentGradient.createShader(bounds),
                    child: const Text(
                      'TUSSI',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Expired Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.borderSubtle),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          isAr ? 'عذراً، الاشتراك منتهي!' : 'Subscription Expired!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          shopName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentAmber,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            expiryText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          inviteCode.isEmpty
                              ? (isAr
                                  ? 'عذراً، هذا المحل لم يعد متوفراً أو تم حذفه من النظام. يرجى التواصل مع الإدارة لمزيد من التفاصيل.'
                                  : 'Sorry, this shop is no longer available or has been deleted from the system. Please contact administration for details.')
                              : (isAr
                                  ? 'لقد انتهت فترة اشتراك محلكم في التطبيق أو تم تعطيلها مؤقتاً من قبل الإدارة. يرجى التواصل معنا لتجديد الاشتراك وتفعيل كود المحل لمواصلة العمل.'
                                  : 'Your shop\'s subscription has expired or has been temporarily disabled. Please contact us to renew your subscription and reactivate the code.'),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (inviteCode.isNotEmpty) ...[
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
                              label: Text(
                                isAr ? 'تجديد الاشتراك عبر الواتساب' : 'Renew via WhatsApp',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              onPressed: _contactAdmin,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextButton.icon(
                          onPressed: () async {
                            await authProvider.signOut();
                          },
                          icon: Icon(Icons.logout_rounded, color: AppTheme.textMuted, size: 16),
                          label: Text(
                            isAr ? 'تسجيل الخروج' : 'Sign Out',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
